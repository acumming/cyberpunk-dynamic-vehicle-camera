
public class DSVCConfig extends ScriptableSystem {
    // General Toggles
    @runtimeProperty("ModSettings.mod", "Dynamic Speed Vehicle Camera")
    @runtimeProperty("ModSettings.category", "General Settings")
    @runtimeProperty("ModSettings.category.order", "0")
    @runtimeProperty("ModSettings.displayName", "Enable Dynamic Camera for Cars")
    @runtimeProperty("ModSettings.description", "Toggle to enable the dynamic camera transitions for cars")
    public let EnableDynamicCamera: Bool = true;

    @runtimeProperty("ModSettings.mod", "Dynamic Speed Vehicle Camera")
    @runtimeProperty("ModSettings.category", "General Settings")
    @runtimeProperty("ModSettings.category.order", "0")
    @runtimeProperty("ModSettings.displayName", "Enable Dynamic Camera for Bikes")
    @runtimeProperty("ModSettings.description", "Toggle to enable the dynamic camera transitions for bikes")
    public let EnableDynamicCameraBikes: Bool = true;

    @runtimeProperty("ModSettings.mod", "Dynamic Speed Vehicle Camera")
    @runtimeProperty("ModSettings.category", "General Settings")
    @runtimeProperty("ModSettings.category.order", "0")
    @runtimeProperty("ModSettings.displayName", "Combat Override")
    @runtimeProperty("ModSettings.description", "Toggle to enable camera override during combat state, independent of dynamic transitions")
    public let CombatOverride: Bool = false;

    @runtimeProperty("ModSettings.mod", "Dynamic Speed Vehicle Camera")
    @runtimeProperty("ModSettings.category", "General Settings")
    @runtimeProperty("ModSettings.category.order", "3")
    @runtimeProperty("ModSettings.displayName", "Default Combat State Camera")
    @runtimeProperty("ModSettings.description", "Select the camera perspective to switch to during combat state, applicable to both cars and bikes")
    @runtimeProperty("ModSettings.displayValues.FPP", "First Person")
    @runtimeProperty("ModSettings.displayValues.TPPClose", "Third Person Close")
    @runtimeProperty("ModSettings.displayValues.TPPMedium", "Third Person Medium")
    @runtimeProperty("ModSettings.displayValues.TPPFar", "Third Person Far")
    @runtimeProperty("ModSettings.displayValues.DriverCombatClose", "Combat Close")
    @runtimeProperty("ModSettings.displayValues.DriverCombatMedium", "Combat Medium")
    @runtimeProperty("ModSettings.displayValues.DriverCombatFar", "Combat Far")
    @runtimeProperty("ModSettings.dependency", "CombatOverride")
    public let DefaultCombatCamera: vehicleCameraPerspective = vehicleCameraPerspective.DriverCombatMedium;

    // Delay settings
    @runtimeProperty("ModSettings.mod", "Dynamic Speed Vehicle Camera")
    @runtimeProperty("ModSettings.category", "General Settings")
    @runtimeProperty("ModSettings.category.order", "0")
    @runtimeProperty("ModSettings.step", "0.1")
    @runtimeProperty("ModSettings.min", "0.0")
    @runtimeProperty("ModSettings.max", "10.0")
    @runtimeProperty("ModSettings.displayName", "Camera Change Delay")
    @runtimeProperty("ModSettings.description", "Amount of time in seconds before the camera transitions to the new perspective. Default: 2 seconds")
    @runtimeProperty("ModSettings.dependency", "EnableDynamicCamera")
    public let cameraChangeDelay: Float = 2.0;

    @runtimeProperty("ModSettings.mod", "Dynamic Speed Vehicle Camera")
    @runtimeProperty("ModSettings.category", "General Settings")
    @runtimeProperty("ModSettings.category.order", "0")
    @runtimeProperty("ModSettings.displayName", "Time Dilation Effects Delay")
    @runtimeProperty("ModSettings.description", "Enable to allow time dilation effects like the scanner to effect the delay time. Default: off")
    @runtimeProperty("ModSettings.dependency", "EnableDynamicCamera")
    public let timeDilationEffectsDelay: Bool = false;

    // Car Settings
    @runtimeProperty("ModSettings.mod", "Dynamic Speed Vehicle Camera")
    @runtimeProperty("ModSettings.category", "Car Settings")
    @runtimeProperty("ModSettings.category.order", "1")
    @runtimeProperty("ModSettings.displayName", "Assumed Max Speed")
    @runtimeProperty("ModSettings.description", "Default value for max MPH, the value will adjust accordingly to your max driving speed")
    @runtimeProperty("ModSettings.step", "1")
    @runtimeProperty("ModSettings.min", "5")
    @runtimeProperty("ModSettings.max", "300")
    @runtimeProperty("ModSettings.dependency", "EnableDynamicCamera")
    public let defaultMaxSpeed: Int32 = 55;

    @runtimeProperty("ModSettings.mod", "Dynamic Speed Vehicle Camera")
    @runtimeProperty("ModSettings.category", "Car Settings")
    @runtimeProperty("ModSettings.category.order", "1")
    @runtimeProperty("ModSettings.displayName", "Car Breakpoint 1")
    @runtimeProperty("ModSettings.description", "Percentage of Assumed Max Speed to trigger transition from First Person to Third Person Close; set the value to 0 to disable First Person")
    @runtimeProperty("ModSettings.step", "1.0")
    @runtimeProperty("ModSettings.min", "0.0")
    @runtimeProperty("ModSettings.max", "100.0")
    @runtimeProperty("ModSettings.dependency", "EnableDynamicCamera")
    public let FPPtoTPP: Float = 25.0;

    @runtimeProperty("ModSettings.mod", "Dynamic Speed Vehicle Camera")
    @runtimeProperty("ModSettings.category", "Car Settings")
    @runtimeProperty("ModSettings.category.order", "1")
    @runtimeProperty("ModSettings.displayName", "Car Breakpoint 2")
    @runtimeProperty("ModSettings.description", "Percentage of Assumed Max Speed to trigger transition from Third Person Close to Medium")
    @runtimeProperty("ModSettings.step", "1.0")
    @runtimeProperty("ModSettings.min", "0.0")
    @runtimeProperty("ModSettings.max", "100.0")
    @runtimeProperty("ModSettings.dependency", "EnableDynamicCamera")
    public let CloseToMedium: Float = 50.0;

    @runtimeProperty("ModSettings.mod", "Dynamic Speed Vehicle Camera")
    @runtimeProperty("ModSettings.category", "Car Settings")
    @runtimeProperty("ModSettings.category.order", "1")
    @runtimeProperty("ModSettings.displayName", "Car Breakpoint 3")
    @runtimeProperty("ModSettings.description", "Percentage of Assumed Max Speed to trigger transition from Third Person Medium to Far")
    @runtimeProperty("ModSettings.step", "1.0")
    @runtimeProperty("ModSettings.min", "0.0")
    @runtimeProperty("ModSettings.max", "100.0")
    @runtimeProperty("ModSettings.dependency", "EnableDynamicCamera")
    public let MediumToFar: Float = 75.0;

    @runtimeProperty("ModSettings.mod", "Dynamic Speed Vehicle Camera")
    @runtimeProperty("ModSettings.category", "Car Settings")
    @runtimeProperty("ModSettings.category.order", "1")
    @runtimeProperty("ModSettings.displayName", "Exclude Third Person Far (Cars)")
    @runtimeProperty("ModSettings.description", "Toggle to exclude Third Person Far for cars; Breakpoint 3 will be ignored")
    @runtimeProperty("ModSettings.dependency", "EnableDynamicCamera")
    public let ExcludeTPPFar: Bool = false;

    // Bike Settings
    @runtimeProperty("ModSettings.mod", "Dynamic Speed Vehicle Camera")
    @runtimeProperty("ModSettings.category", "Bike Settings")
    @runtimeProperty("ModSettings.category.order", "2")
    @runtimeProperty("ModSettings.displayName", "Assumed Max Speed")
    @runtimeProperty("ModSettings.description", "Default value for max MPH, the value will adjust accordingly to your max driving speed")
    @runtimeProperty("ModSettings.step", "1")
    @runtimeProperty("ModSettings.min", "5")
    @runtimeProperty("ModSettings.max", "300")
    @runtimeProperty("ModSettings.dependency", "EnableDynamicCameraBikes")
    public let defaultMaxSpeedBikes: Int32 = 45;

    @runtimeProperty("ModSettings.mod", "Dynamic Speed Vehicle Camera")
    @runtimeProperty("ModSettings.category", "Bike Settings")
    @runtimeProperty("ModSettings.category.order", "2")
    @runtimeProperty("ModSettings.displayName", "Bike Breakpoint 1")
    @runtimeProperty("ModSettings.description", "Percentage of Assumed Max Speed to trigger transition from First Person to Third Person Close; set the value to 0 to disable First Person")
    @runtimeProperty("ModSettings.step", "1.0")
    @runtimeProperty("ModSettings.min", "0.0")
    @runtimeProperty("ModSettings.max", "100.0")
    @runtimeProperty("ModSettings.dependency", "EnableDynamicCameraBikes")
    public let FPPtoTPPBike: Float = 25.0;

    @runtimeProperty("ModSettings.mod", "Dynamic Speed Vehicle Camera")
    @runtimeProperty("ModSettings.category", "Bike Settings")
    @runtimeProperty("ModSettings.category.order", "2")
    @runtimeProperty("ModSettings.displayName", "Bike Breakpoint 2")
    @runtimeProperty("ModSettings.description", "Percentage of Assumed Max Speed to trigger transition from Third Person Close to Medium")
    @runtimeProperty("ModSettings.step", "1.0")
    @runtimeProperty("ModSettings.min", "0.0")
    @runtimeProperty("ModSettings.max", "100.0")
    @runtimeProperty("ModSettings.dependency", "EnableDynamicCameraBikes")
    public let CloseToMediumBike: Float = 50.0;

    @runtimeProperty("ModSettings.mod", "Dynamic Speed Vehicle Camera")
    @runtimeProperty("ModSettings.category", "Bike Settings")
    @runtimeProperty("ModSettings.category.order", "2")
    @runtimeProperty("ModSettings.displayName", "Bike Breakpoint 3")
    @runtimeProperty("ModSettings.description", "Percentage of Assumed Max Speed to trigger transition from Third Person Medium to Far")
    @runtimeProperty("ModSettings.step", "1.0")
    @runtimeProperty("ModSettings.min", "0.0")
    @runtimeProperty("ModSettings.max", "100.0")
    @runtimeProperty("ModSettings.dependency", "EnableDynamicCameraBikes")
    public let MediumToFarBike: Float = 75.0;

    @runtimeProperty("ModSettings.mod", "Dynamic Speed Vehicle Camera")
    @runtimeProperty("ModSettings.category", "Bike Settings")
    @runtimeProperty("ModSettings.category.order", "2")
    @runtimeProperty("ModSettings.displayName", "Exclude Third Person Far (Bikes)")
    @runtimeProperty("ModSettings.description", "Toggle to exclude Third Person Far for bikes; Breakpoint 3 will be ignored")
    @runtimeProperty("ModSettings.dependency", "EnableDynamicCameraBikes")
    public let ExcludeTPPFarBike: Bool = false;

    public let activeVehicleMaxSpeedSeen: Int32;
    public let lastActiveVehicle: wref<VehicleObject>;
    public let cachedVehicleType: gamedataVehicleType;

    public static func Get(gi: GameInstance) -> ref<DSVCConfig> {
        return GameInstance.GetScriptableSystemsContainer(gi).Get(n"DSVCConfig") as DSVCConfig;
    }

    private func OnAttach() -> Void {
        dsvcRegisterListener(this);
    }

    private func OnDetach() -> Void {
        dsvcUnregisterListener(this);
    }
}

@if(ModuleExists("ModSettingsModule"))
public func dsvcRegisterListener(listener: ref<IScriptable>) {
    ModSettings.RegisterListenerToClass(listener);
}

@if(ModuleExists("ModSettingsModule"))
public func dsvcUnregisterListener(listener: ref<IScriptable>) {
    ModSettings.UnregisterListenerToClass(listener);
}

@if(!ModuleExists("ModSettingsModule"))
public func dsvcRegisterListener(listener: ref<IScriptable>) {
}

@if(!ModuleExists("ModSettingsModule"))
public func dsvcUnregisterListener(listener: ref<IScriptable>) {
}
