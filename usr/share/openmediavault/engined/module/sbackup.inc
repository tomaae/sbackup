<?php

class OMVModuleSbackup extends \OMV\Engine\Module\ServiceAbstract 
implements \OMV\Engine\Notify\IListener {
	/**
	* Get the module name.
	*/
	public function getName() {
		return "sbackup";
	}

	/**
	* Generate the configuration.
	* @throw E_EXEC_FAILED
	*/
	public function applyConfig() {
		$cmd = new \OMV\System\Process("omv-mkconf", "sbackup");
		$cmd->setRedirect2to1();
		$cmd->execute();
	}

	/**
	* Helper function to find out whether the given shared folder
	* configuration object is used. If it is used, then mark the
	* module as dirty.
	* @param type The event message type.
	* @param path The event message path.
	* @param object The configuration object.
	*/
//	final public function onSharedFolder($type, $path, $object) {
//		global $xmlConfig;
//		$xpath = sprintf("//services/sbackup/backuplist/backup[source_sharedfolder_uuid='%s']", $object['uuid']);
//		if(TRUE === $xmlConfig->exists($xpath))$this->setDirty();
//		$xpath = sprintf("//services/sbackup/backuplist/backup[target_sharedfolder_uuid='%s']", $object['uuid']);
//		if(TRUE === $xmlConfig->exists($xpath))$this->setDirty();
//	}

	/**
	* Bind listeners.
	*/
	function bindListeners(\OMV\Engine\Notify\Dispatcher $dispatcher) {
		$dispatcher->addListener(
			OMV_NOTIFY_CREATE | OMV_NOTIFY_MODIFY | OMV_NOTIFY_DELETE,
			"org.openmediavault.conf.service.sbackup",
			[ $this, "setDirty" ]
		);
//		$dispatcher->addListener(
//			OMV_NOTIFY_MODIFY,
//			"org.openmediavault.system.shares.sharedfolder",
//			array($this, "onSharedFolder")
//		);
	}
}

?>
