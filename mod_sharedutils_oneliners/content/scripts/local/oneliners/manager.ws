
///
statemachine class SUOL_Manager extends SU_StorageItem {
  default tag = "SUOL_Manager";

  /// an internal counter
  private var oneliner_counter: int;

  /// A list of all the active oneliners
  protected var oneliners: array<SU_Oneliner>;

  /// A list of all the oneliners that should appear in the status bar
  protected var status_bar_oneliners: array<SU_OnelinerStatus>;

  /// A garbage type of array that stores the IDs of old, deleted sprites so
  /// that when asking for a new ID it returns an old recycled one instead.
  private var oneliners_garbage: array<int>;

  //////////////////////////////////////////////////////////////////////////////
  // statemachine workflow code:

  protected var module_oneliners: CR4HudModuleOneliners;
  protected var module_flash: CScriptedFlashSprite;
  protected var module_hud: CR4ScriptedHud;

  private var fxCreateOnelinerSFF: CScriptedFlashFunction;
  private var fxRemoveOnelinerSFF: CScriptedFlashFunction;

  private function initialize() {
    this.module_hud = (CR4ScriptedHud)theGame.GetHud();
    this.module_oneliners = (CR4HudModuleOneliners)(this.module_hud.GetHudModule( "OnelinersModule" ));
    this.module_flash = this.module_oneliners.GetModuleFlash();

		this.fxCreateOnelinerSFF 	= this.module_flash.GetMemberFlashFunction( "CreateOneliner" );
		this.fxRemoveOnelinerSFF 	= this.module_flash.GetMemberFlashFunction( "RemoveOneliner" );
  }

  private function getNewId(): int {
    var id: int;

    if (this.oneliners_garbage.Size() > 0) {
      id = this.oneliners_garbage.PopBack();
    }
    else {
      this.oneliner_counter += 1;
      id = this.oneliner_counter;
    }

    return id;
  }

  private function initializeStatusBarOffsets() {
		var oneliner: SU_OnelinerStatus;
		var left_offset: float;
		var i: int;

		for (i = 0; i < this.status_bar_oneliners.Size(); i += 1) {
			oneliner = this.status_bar_oneliners[i];

      // As we add status oneliners, we push them further and further to the left
      // So they slowly appear one by one.
      left_offset += (float)StrLen(oneliner.text) * -0.02 + 0.1;

			this.status_bar_oneliners[i].offset = Vector(left_offset, 0);
			this.status_bar_oneliners[i].position = Vector(0, 0.97);
		}
	}

  //////////////////////////////////////////////////////////////////////////////
  // public API:

  public function createOneliner(oneliner: SU_Oneliner) {
    var should_initialize_and_render: bool;

    should_initialize_and_render = this.GetCurrentStateName() != 'Render';

    if (should_initialize_and_render) {
      this.initialize();
    }

    oneliner.id = this.getNewId();
    this.updateOneliner(oneliner);
    this.oneliners.PushBack(oneliner);

    if (should_initialize_and_render) {
      this.GotoState('Render');
    }
  }

  /// Updates the flash values with the oneliner's new/current text
  public function updateOneliner(oneliner: SU_Oneliner) {
    this.fxCreateOnelinerSFF.InvokeSelfTwoArgs(
      FlashArgInt(oneliner.id),
      FlashArgString(oneliner.text)
    );
  }

  public function deleteOneliner(oneliner: SU_Oneliner) {
    this.oneliners.Remove(oneliner);
    this.oneliners_garbage.PushBack(oneliner.id);
    this.fxRemoveOnelinerSFF.InvokeSelfOneArg(FlashArgInt(oneliner.id));
  }

  public function createOnelinerStatus(oneliner: SU_OnelinerStatus) {
    var should_initialize_and_render: bool;

    should_initialize_and_render = this.GetCurrentStateName() != 'Render';

    if (should_initialize_and_render) {
      this.initialize();
    }

    oneliner.id = this.getNewId();
    this.updateOneliner(oneliner);
    this.status_bar_oneliners.PushBack(oneliner);
    this.initializeStatusBarOffsets();

    if (should_initialize_and_render) {
      this.GotoState('Render');
    }
  }

  public function deleteOnelinerStatus(oneliner: SU_OnelinerStatus) {
    this.status_bar_oneliners.Remove(oneliner);
    this.oneliners_garbage.PushBack(oneliner.id);
    this.fxRemoveOnelinerSFF.InvokeSelfOneArg(FlashArgInt(oneliner.id));
    this.initializeStatusBarOffsets();
  }
}
