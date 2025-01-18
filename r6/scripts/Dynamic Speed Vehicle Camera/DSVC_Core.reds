
native func LogChannel(channel: CName, text: script_ref<String>);

@addField(VehicleComponent)
public let inCombat: Bool = false;

@addField(VehicleComponent)
public let dsvcConfig: ref<DSVCConfig>;

// Because we can't ewasily check if this is the first run of the
// OnVehicleSpeedChange function we need a way to check if a last perspective
// has been set. There may be a better way to do this by running initialization
// when the player first enters the car, but I couldn't figure that out.
// May also need to be reset when the player exits the car?
@addField(VehicleComponent)
public let hasLastPerspective: Bool = false;

// This is the last perspective that was queued. This is used to throttle so we
// don't run the whole caluculation on every tick, just when there's been a
// change in camery perspective.
@addField(VehicleComponent)
public let lastQueuedPerspective: vehicleCameraPerspective = vehicleCameraPerspective.TPPMedium;

// Delay identifier from the DelaySystem. Finicky for some reason.
// Ref https://nativedb.red4ext.com/s/1299193313933399
@addField(VehicleComponent)
public let cameraEventDelayID: DelayID;

@wrapMethod(VehicleComponent)
protected final func OnVehicleSpeedChange(speed: Float) -> Void {
    // Moved this to top to avoid having to call it on every return of the
    // function
    wrappedMethod(speed);

    // For checking against previous state
    let newPerspective: vehicleCameraPerspective;

    // Caching. Not sure if this will cause issues.
    let vehicle: wref<VehicleObject> = this.GetVehicle();
    let gameInstance: GameInstance = GetGameInstance();
    let player: ref<PlayerPuppet> = GetPlayer(gameInstance);

    // Fetch config
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
    // TODO: How to handle AVs? They are not in the VehicleType enum
    // Can check against the record name starting with "av_" maybe?
    let vehicleRecord = TweakDBInterface.GetVehicleRecord(vehicle.GetRecordID());
    let vehicleType = vehicleRecord.Type().Type();

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
        // LogChannel(
        //     n"DynamicVehicleCamera",
        //     "Skipping camera event, already queued: " + ToString(newPerspective)
        // );
        return;
    }
    // LogChannel(
    //     n"DynamicVehicleCamera",
    //     "setting newPerspective to " + ToString(newPerspective) + " at " + ToString(mph) + " mph"
    // );
    this.hasLastPerspective = true;
    this.lastQueuedPerspective = newPerspective;
    camEvent.cameraPerspective = newPerspective;

    // Set up the delay system
    // Ref https://wiki.redmodding.org/redscript/references-and-examples/common-patterns/delaysystem-and-delaycallback
    let delaySystem: ref<DelaySystem> = GameInstance.GetDelaySystem(gameInstance);
    let delay: Float = cameraChangeDelay;
    let isAffectedByTimeDilation: Bool = timeDilationEffectsDelay;

    if IsDefined(delaySystem) {
        let callback: ref<CameraEventCustomCallback> = CameraEventCustomCallback.Create(player, camEvent);

        // Before scheduling a new callback, cancel last one if it exists
        // Pevents queueing up of multiple camera events
        // Using this.cameraEventDelayID eq GetInvalidDelayID() does not work
        // for some reason, but using != new DelayID() does
        // https://nativedb.red4ext.com/f/8390577877113592
        if this.cameraEventDelayID != new DelayID() {
            // LogChannel(
            //     n"DynamicVehicleCamera",
            //     "Cancelling existing camera event delay: " + ToString(this.cameraEventDelayID)
            // );
            delaySystem.CancelCallback(this.cameraEventDelayID);
        }

        // LogChannel(
        //     n"DynamicVehicleCamera",
        //     "remaining delay: "
        //         + ToString(delaySystem.GetRemainingDelayTime(this.cameraEventDelayID))
        // );

        this.cameraEventDelayID = delaySystem.DelayCallback(callback, delay, isAffectedByTimeDilation);
    } else {
        // LogChannel(
        //     n"DynamicVehicleCamera",
        //     "Scheduling new camera event delay: " + ToString(this.cameraEventDelayID)
        // );

        LogChannel(n"DynamicVehicleCamera", "DelaySystem not defined");
    }
}

/**
 * Custom callback class that will be used to queue the camera event after the specified delay
 * https://wiki.redmodding.org/cyberpunk-2077-modding/modding-guides/sound/custom-sounds-and-custom-emitters-with-audioware
 */
// TODO: add toggle for AVs
// TODO: add a manual cancel when the user changes the camera manually
public class CameraEventCustomCallback extends DelayCallback {
    private let playerRef: ref<PlayerPuppet>;
    private let camEventRef: ref<vehicleRequestCameraPerspectiveEvent>;

    public func Call() {
        // LogChannel(
        //     n"DynamicVehicleCamera",
        //     "Callback Call, changing to " + ToString(this.camEventRef.cameraPerspective)
        // );

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
        // LogChannel(
        //     n"DynamicVehicleCamera",
        //     "Creating new CameraEventCustomCallback with " + ToString(camEvent.cameraPerspective)
        // );

        return self;
    }
}
