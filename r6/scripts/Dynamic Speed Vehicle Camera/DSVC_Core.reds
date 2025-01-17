native func LogChannel(channel: CName, text: script_ref<String>)

@addField(VehicleComponent) public let inCombat: Bool = false;
@addField(VehicleComponent) public let dsvcConfig: ref<DSVCConfig>;

@wrapMethod(VehicleComponent)
protected final func OnVehicleSpeedChange(speed: Float) -> Void {
    this.dsvcConfig = DSVCConfig.Get(this.GetVehicle().GetGame());

    let player = GetPlayer(this.GetVehicle().GetGame());

    // Combat override Logic
    if this.dsvcConfig.CombatOverride && player.IsInCombat() {
        if !this.inCombat {
            // LogChannel(n"DynamicVehicleCamera", s"Switching to combat camera: \(this.dsvcConfig.DefaultCombatCamera)");
            let combatCamEvent: ref<vehicleRequestCameraPerspectiveEvent> = new vehicleRequestCameraPerspectiveEvent();
            combatCamEvent.cameraPerspective = this.dsvcConfig.DefaultCombatCamera;
            player.QueueEvent(combatCamEvent);
            this.inCombat = true;
        }
        return; // Skip dynamic transitions in combat
    }

    if this.inCombat && !player.IsInCombat() {
        // LogChannel(n"DynamicVehicleCamera", s"Exiting combat, resuming dynamic camera");
        this.inCombat = false; // Reset combat state
    }

    speed = AbsF(speed);
    let multiplier: Float = GameInstance.GetStatsDataSystem(this.GetVehicle().GetGame()).GetValueFromCurve(n"vehicle_ui", speed, n"speed_to_multiplier");
    let mph: Int32 = RoundMath(speed * multiplier);

    if Equals(this.dsvcConfig.lastActiveVehicle, this.GetVehicle()) {
        if mph > this.dsvcConfig.activeVehicleMaxSpeedSeen {
            this.dsvcConfig.activeVehicleMaxSpeedSeen = mph;
        }
    } else {
        this.dsvcConfig.activeVehicleMaxSpeedSeen = this.dsvcConfig.defaultMaxSpeed;
        this.dsvcConfig.lastActiveVehicle = this.GetVehicle();
    }

    let speedPercentageOfMax = (Cast<Float>(mph) / Cast<Float>(this.dsvcConfig.activeVehicleMaxSpeedSeen)) * 100.0;

    let camEvent: ref<vehicleRequestCameraPerspectiveEvent> = new vehicleRequestCameraPerspectiveEvent();

    // Determine vehicle type
    let vehicleRecord = TweakDBInterface.GetVehicleRecord(this.GetVehicle().GetRecordID());
    let vehicleType = vehicleRecord.Type().Type();

    // Respect toggles for cars and bikes
    let excludeTPPFar: Bool;
    let fppToTPP: Float;
    let closeToMedium: Float;
    let mediumToFar: Float;

    switch vehicleType {
        case gamedataVehicleType.Bike:
            if !this.dsvcConfig.EnableDynamicCameraBikes {
                return; // Skip dynamic transitions for bikes if the toggle is off
            }
            excludeTPPFar = this.dsvcConfig.ExcludeTPPFarBike;
            fppToTPP = this.dsvcConfig.FPPtoTPPBike;
            closeToMedium = this.dsvcConfig.CloseToMediumBike;
            mediumToFar = this.dsvcConfig.MediumToFarBike;
            break;
        default:
            if !this.dsvcConfig.EnableDynamicCamera {
                return; // Skip dynamic transitions for cars if the toggle is off
            }
            excludeTPPFar = this.dsvcConfig.ExcludeTPPFar;
            fppToTPP = this.dsvcConfig.FPPtoTPP;
            closeToMedium = this.dsvcConfig.CloseToMedium;
            mediumToFar = this.dsvcConfig.MediumToFar;
            break;
    }

    // Dynamic Camera Logic

	if fppToTPP > Cast<Float>(0) && speedPercentageOfMax < fppToTPP {
	    camEvent.cameraPerspective = vehicleCameraPerspective.FPP;
	    if this.GetVehicle().IsVehicleRemoteControlled() || !VehicleComponent.IsDriver(this.GetVehicle().GetGame(), player) {
	        camEvent.cameraPerspective = vehicleCameraPerspective.TPPClose;
	    }
	} else if speedPercentageOfMax < closeToMedium {
	    camEvent.cameraPerspective = vehicleCameraPerspective.TPPClose;
	} else if speedPercentageOfMax >= closeToMedium && speedPercentageOfMax < mediumToFar {
	    camEvent.cameraPerspective = vehicleCameraPerspective.TPPMedium;
	} else if speedPercentageOfMax >= mediumToFar {
	    if !excludeTPPFar {
	        camEvent.cameraPerspective = vehicleCameraPerspective.TPPFar;
	    } else {
	        camEvent.cameraPerspective = vehicleCameraPerspective.TPPMedium; // Default to Medium
	    }
	}

    player.QueueEvent(camEvent);
    wrappedMethod(speed);
}
