<?php
require_once("openmediavault/module.inc");
require_once("openmediavault/config.inc");
require_once("openmediavault/error.inc");

class OMVModuleSBackup extends OMVModuleServiceAbstract
implements OMVINotifyListener {
	/**
	* Get the module name.
	*/
	public function getName() {
		return "SBackup";
	}

	/**
	* Generate the configuration.
	* @throw E_EXEC_FAILED
	*/
	public function applyConfig() {
		$cmd = "omv-mkconf sbackup 2>&1";
		if(0 !== $this->exec($cmd, $output)) {
			throw new OMVException(OMVErrorMsg::E_EXEC_FAILED,
			$cmd, implode("\n", $output));
		}
	}

	/**
	* Helper function to find out whether the given shared folder
	* configuration object is used. If it is used, then mark the
	* module as dirty.
	* @param type The event message type.
	* @param path The event message path.
	* @param object The configuration object.
	*/
	final public function onSharedFolder($type, $path, $object) {
		global $xmlConfig;
		$xpath = sprintf("//services/sbackup/backuplist/backup[source_sharedfolder_uuid='%s']", $object['uuid']);
		if(TRUE === $xmlConfig->exists($xpath))$this->setDirty();
		$xpath = sprintf("//services/sbackup/backuplist/backup[target_sharedfolder_uuid='%s']", $object['uuid']);
		if(TRUE === $xmlConfig->exists($xpath))$this->setDirty();
	}

	/**
	* Bind listeners.
	*/
	function bindListeners(OMVNotifyDispatcher $dispatcher) {
		$dispatcher->addListener(
		OMV_NOTIFY_CREATE | OMV_NOTIFY_MODIFY | OMV_NOTIFY_DELETE,
		"org.openmediavault.services.sbackup.backuplist.backup",
		array($this, "setDirty"));
		$dispatcher->addListener(
		OMV_NOTIFY_CREATE | OMV_NOTIFY_MODIFY | OMV_NOTIFY_DELETE,
		"org.openmediavault.services.sbackup.settings",
		array($this, "setDirty"));
		$dispatcher->addListener(
		OMV_NOTIFY_MODIFY,
		"org.openmediavault.system.shares.sharedfolder",
		array($this, "onSharedFolder"));
	}
}

// Register module.
$moduleMgr = &OMVModuleMgr::getInstance();
$moduleMgr->registerModule(new OMVModuleSBackup());
?>
