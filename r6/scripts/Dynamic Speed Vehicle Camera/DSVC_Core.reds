
native func LogChannel(channel: CName, text: script_ref<String>);

@addField(VehicleComponent)
public let inCombat: Bool = false;

@addField(VehicleComponent)
public let dsvcConfig: ref<DSVCConfig>;

@addField(VehicleComponent)
public let hasLastPerspective: Bool = false;

@addField(VehicleComponent)
public let lastQueuedPerspective: vehicleCameraPerspective = vehicleCameraPerspective.TPPMedium;

@addField(VehicleComponent)
public let cameraEventDelayID: DelayID;

@wrapMethod(VehicleComponent)
protected final func OnVehicleSpeedChange(speed: Float) -> Void {
    let newPerspective: vehicleCameraPerspective;

    // Caching. Not sure if this will cause issues.
    let vehicle: wref<VehicleObject> = this.GetVehicle();
    let gameInstance: GameInstance = GetGameInstance();
    let player = GetPlayer(gameInstance);

    this.dsvcConfig = DSVCConfig.Get(gameInstance);

    // New configuration values
    let cameraChangeDelay: Float = this.dsvcConfig.cameraChangeDelay;
    let timeDilationEffectsDelay: Bool = this.dsvcConfig.timeDilationEffectsDelay;

    // Combat override Logic
    if this.dsvcConfig.CombatOverride && player.IsInCombat() {
        if !this.inCombat {
            LogChannel(
                n"DynamicVehicleCamera",
                s"Switching to combat camera: \(this.dsvcConfig.DefaultCombatCamera)"
            );
            let combatCamEvent: ref<vehicleRequestCameraPerspectiveEvent> = new vehicleRequestCameraPerspectiveEvent();
            combatCamEvent.cameraPerspective = this.dsvcConfig.DefaultCombatCamera;
            player.QueueEvent(combatCamEvent);
            this.inCombat = true;
        }
        return;
    }
    // Skip dynamic transitions in combat

    if this.inCombat && !player.IsInCombat() {
        LogChannel(n"DynamicVehicleCamera", s"Exiting combat, resuming dynamic camera");
        this.inCombat = false;
    }
    // Reset combat state

    speed = AbsF(speed);
    let multiplier: Float = GameInstance
        .GetStatsDataSystem(gameInstance)
        .GetValueFromCurve(n"vehicle_ui", speed, n"speed_to_multiplier");
    let mph: Int32 = RoundMath(speed * multiplier);

    if Equals(this.dsvcConfig.lastActiveVehicle, vehicle) {
        if mph > this.dsvcConfig.activeVehicleMaxSpeedSeen {
            this.dsvcConfig.activeVehicleMaxSpeedSeen = mph;
        }
    } else {
        this.dsvcConfig.activeVehicleMaxSpeedSeen = this.dsvcConfig.defaultMaxSpeed;
        this.dsvcConfig.lastActiveVehicle = vehicle;
    }

    let speedPercentageOfMax = Cast<Float>(mph) / Cast<Float>(this.dsvcConfig.activeVehicleMaxSpeedSeen) * 100.0;

    let camEvent: ref<vehicleRequestCameraPerspectiveEvent> = new vehicleRequestCameraPerspectiveEvent();

    // Determine vehicle type
    let vehicleRecord = TweakDBInterface.GetVehicleRecord(vehicle.GetRecordID());
    let vehicleType = vehicleRecord.Type().Type();
    let vehicleClassName: CName = vehicleRecord.GetClassName();
    let vehicleDisplayName: CName = vehicleRecord.DisplayName();
    LogChannel(n"DynamicVehicleCamera", s"vehicleClassName: " + ToString(vehicleClassName));
    LogChannel(
        n"DynamicVehicleCamera",
        s"vehicleDisplayName: " + ToString(vehicleDisplayName)
    );

    // Respect toggles for cars and bikes
    let excludeTPPFar: Bool;
    let fppToTPP: Float;
    let closeToMedium: Float;
    let mediumToFar: Float;

    switch vehicleType {
        case gamedataVehicleType.Bike:
            if !this.dsvcConfig.EnableDynamicCameraBikes {
                return;
            }
            // Skip dynamic transitions for bikes if the toggle is off

            excludeTPPFar = this.dsvcConfig.ExcludeTPPFarBike;
            fppToTPP = this.dsvcConfig.FPPtoTPPBike;
            closeToMedium = this.dsvcConfig.CloseToMediumBike;
            mediumToFar = this.dsvcConfig.MediumToFarBike;
            break;
        default:
            if !this.dsvcConfig.EnableDynamicCamera {
                return;
            }
            // Skip dynamic transitions for cars if the toggle is off

            excludeTPPFar = this.dsvcConfig.ExcludeTPPFar;
            fppToTPP = this.dsvcConfig.FPPtoTPP;
            closeToMedium = this.dsvcConfig.CloseToMedium;
            mediumToFar = this.dsvcConfig.MediumToFar;
            break;
    }

    // Dynamic Camera Logic

    if fppToTPP > Cast<Float>(0) && speedPercentageOfMax < fppToTPP {
        newPerspective = vehicleCameraPerspective.FPP;
        if vehicle.IsVehicleRemoteControlled() || !VehicleComponent.IsDriver(gameInstance, player) {
            newPerspective = vehicleCameraPerspective.TPPClose;
        }
    } else if speedPercentageOfMax < closeToMedium {
        newPerspective = vehicleCameraPerspective.TPPClose;
    } else if speedPercentageOfMax >= closeToMedium && speedPercentageOfMax < mediumToFar {
        newPerspective = vehicleCameraPerspective.TPPMedium;
    } else if speedPercentageOfMax >= mediumToFar {
        if !excludeTPPFar {
            newPerspective = vehicleCameraPerspective.TPPFar;
        } else {
            newPerspective = vehicleCameraPerspective.TPPMedium;
        }
    }
    // Default to Medium

    // Check if the new perspective is the same as the last queued one
    // If it is, skip scheduling a new callback
    // This is to throttle the camera events
    if this.hasLastPerspective && Equals(newPerspective, this.lastQueuedPerspective) {
        return;
    }
    this.hasLastPerspective = true;
    this.lastQueuedPerspective = newPerspective;
    camEvent.cameraPerspective = newPerspective;

    // Set up the delay system
    let delaySystem: ref<DelaySystem> = GameInstance.GetDelaySystem(GetGameInstance());
    let delay: Float = cameraChangeDelay;
    let isAffectedByTimeDilation: Bool = timeDilationEffectsDelay;

    // Before scheduling a new callback, cancel any existing one
    if !Equals(this.cameraEventDelayID, GetInvalidDelayID()) {
        LogChannel(
            n"DynamicVehicleCamera",
            "Cancelling existing camera event delay: " + ToString(this.cameraEventDelayID)
        );
        delaySystem.CancelCallback(this.cameraEventDelayID);
        this.cameraEventDelayID = GetInvalidDelayID();
    }

    this.cameraEventDelayID = delaySystem
        .DelayCallback(
            CameraEventCustomCallback.Create(player, camEvent),
            delay,
            isAffectedByTimeDilation
        );

    // player.QueueEvent(camEvent);
    wrappedMethod(speed);
}

/**
 * Custom callback class that will be used to queue the camera event after the specified delay
 */
// TODO: add toggle for AVs
// TODO: add a manual cancel when the user changes the camera manually
// TODO: Debounce
public class CameraEventCustomCallback extends DelayCallback {
    // all the data that your Call function needs
    private let playerRef: ref<PlayerPuppet>;
    private let camEventRef: ref<vehicleRequestCameraPerspectiveEvent>;

    // // 4) Store the custom event
    // private let camEventRef: ref<DSVCameraPerspectiveEvent>;
    public func Call() {
        LogChannel(
            n"DynamicVehicleCamera",
            "Callback Call, changing to " + ToString(this.camEventRef.cameraPerspective)
        );

        this.playerRef.QueueEvent(this.camEventRef);
    }

    /**
     * @param player The player that will receive the camera event
     * @param camEvent The camera event that will be queued
     */
    public static func Create(
        player: ref<PlayerPuppet>,
        camEvent: ref<vehicleRequestCameraPerspectiveEvent>
    ) -> ref<CameraEventCustomCallback> {
        let self = new CameraEventCustomCallback();

        self.playerRef = player;
        self.camEventRef = camEvent;

        return self;
    }
}
