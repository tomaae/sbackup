<?php
require_once("openmediavault/object.inc");
require_once("openmediavault/config.inc");
require_once("openmediavault/error.inc");
require_once("openmediavault/rpcservice.inc");
require_once("openmediavault/notify.inc");
//require_once("openmediavault/util.inc");

class OMVRpcServiceSBackup extends OMVRpcServiceAbstract {
	/**
	* Get the RPC service name.
	*/
	public function getName() {
		return "SBackup";
	}

	/**
	* Initialize the RPC service.
	*/
	public function initialize() {
		$this->registerMethod("getHistory");
		$this->registerMethod("getList");
		$this->registerMethod("get");
		$this->registerMethod("set");
		$this->registerMethod("delete");
		$this->registerMethod("showLog");
		$this->registerMethod("runBackup");
		$this->registerMethod("runRestore");
		$this->registerMethod("getRestoreDirBrowser");
		$this->registerMethod("getSettings");
		$this->registerMethod("setSettings");
		$this->registerMethod("getVersions");
	}

	/**
	* getHistory
	*/
	public function getHistory($params, $context) {
		global $xmlConfig;
		// Validate the RPC caller context.
		$this->validateMethodContext($context, array(
		"role" => OMV_ROLE_ADMINISTRATOR
		));
		// Validate the parameters of the RPC service method.
		$this->validateMethodParams($params, '{
		"type":"object",
		"properties":{
		"start":{"type":"integer"},
		"limit":{'.$GLOBALS['OMV_JSONSCHEMA_COUNTFIELD'].'},
		"sortfield":{'.$GLOBALS['OMV_JSONSCHEMA_SORTFIELD'].'},
		"sortdir":{'.$GLOBALS['OMV_JSONSCHEMA_SORTDIR'].'}
		}
		}');

		// Get the configuration objects.
		$xpath = "//services/sbackup/backuplist/backup";
		$objects = $xmlConfig->getList($xpath);
		if(is_null($objects)) {
			throw new OMVException(OMVErrorMsg::E_CONFIG_GET_OBJECT_FAILED,
			$xpath);
		}
		// Add additional share informations.
		$i=0;
		foreach($objects as $objectk => &$objectv) {
  		if(file_exists("/var/log/sbackup/history_".$objectv['uuid'])){
  			$txt_file = file_get_contents("/var/log/sbackup/history_".$objectv['uuid']);
  			$lines    = explode("\n", $txt_file);
  			foreach($lines as $line){
  				if(!$line)continue;
  				$rows = explode("|", $line);
  				$t_objects[$i]['id'] = $rows[3];
  				$t_objects[$i]['uuid'] = $objectv['uuid'];
  				$t_objects[$i]['name'] = $objectv['name'];
  				if($rows[0] == "0"){
  					$t_objects[$i]['running'] = "Completed";
  				}else{
  					$t_objects[$i]['running'] = "Error:".$rows[0];
  				}
  				if($rows[0] == "running"){
  					$t_objects[$i]['running'] = "Running";
  				}
  				if($rows[3]){$t_objects[$i]['starttime'] = date('r', $rows[3]);}else{$t_objects[$i]['starttime'] = "N/A";}
  				if($rows[4]){$t_objects[$i]['endtime'] = date('r', $rows[4]);}else{$t_objects[$i]['endtime'] = "N/A";}
  				if($rows[5] != ""){$t_objects[$i]['backupsize'] = $rows[5];}else{$t_objects[$i]['backupsize'] = "N/A";}
  				if(file_exists("/var/log/sbackup/sessionlogs/".$objectv['uuid']."_".$rows[3].".log")){
  					$t_objects[$i]['haslog'] = "yes";
  					$t_objects[$i]['fileid'] = $objectv['uuid']."_".$rows[3];
  				}else{
  					$t_objects[$i]['haslog'] = "no";
  				}
  				if($rows[6]){$t_objects[$i]['backupperf'] = $rows[6];}else{$t_objects[$i]['backupperf'] = "N/A";}
    			$t_objects[$i]['sessiontype'] = "Backup";#"N/A";
  				if($rows[7] == "backup")$t_objects[$i]['sessiontype'] = "Backup";
  				if($rows[7] == "restore")$t_objects[$i]['sessiontype'] = "Restore";
  				
  				$i++;
  			}
  		}
		}
		// Filter the result.
		return $this->applyFilter($t_objects, $params['start'],
		$params['limit'], $params['sortfield'], $params['sortdir']);
	}

	/**
	* getList
	*/
	public function getList($params, $context) {
		global $xmlConfig;
		// Validate the RPC caller context.
		$this->validateMethodContext($context, array(
		"role" => OMV_ROLE_ADMINISTRATOR
		));
		// Validate the parameters of the RPC service method.
		$this->validateMethodParams($params, '{
		"type":"object",
		"properties":{
		"start":{"type":"integer"},
		"limit":{'.$GLOBALS['OMV_JSONSCHEMA_COUNTFIELD'].'},
		"sortfield":{'.$GLOBALS['OMV_JSONSCHEMA_SORTFIELD'].'},
		"sortdir":{'.$GLOBALS['OMV_JSONSCHEMA_SORTDIR'].'}
		}
		}');
		// Get the configuration objects.
		$xpath = "//services/sbackup/backuplist/backup";
		$objects = $xmlConfig->getList($xpath);
		if(is_null($objects)) {
			throw new OMVException(OMVErrorMsg::E_CONFIG_GET_OBJECT_FAILED,
			$xpath);
		}
		// Add additional share informations.
		foreach($objects as $objectk => &$objectv) {

			// Get the shared folder configuration object.
			$objectv['sourcefoldername'] = gettext("n/a");
			$sfobject = $xmlConfig->get("//system/shares/sharedfolder[uuid='{$objectv['sharedfoldersource']}']");
			if(!is_null($sfobject) && !empty($sfobject)) {
				$objectv['sourcefoldername'] = $sfobject['name'];
			}

			// Get the shared folder configuration object.
			$objectv['targetfoldername'] = gettext("n/a");
			$sfobject = $xmlConfig->get("//system/shares/sharedfolder[uuid='{$objectv['sharedfoldertarget']}']");
			if(!is_null($sfobject) && !empty($sfobject)) {
				$objectv['targetfoldername'] = $sfobject['name'];
			}

			// Get last job status
			$objectv['running'] = "N/A";
			$objectv['lastcompleted'] = "N/A";
			if(file_exists(sprintf("/var/run/sbackup_%s", $objectv['uuid']))){
				$txt_file           = file_get_contents(sprintf("/var/run/sbackup_%s", $objectv['uuid']));
				$rows               = explode("|", $txt_file);
				if($rows[0] == "backup")$objectv['running'] = "Running";
				if($rows[0] == "restore")$objectv['running'] = "Restoring";
			}
			$objectv['versions'] = 0;
			if(file_exists(sprintf("/var/log/sbackup/history_%s", $objectv['uuid']))){
				$txt_file = file_get_contents(sprintf("/var/log/sbackup/history_%s", $objectv['uuid']));
				$lines    = explode("\n", $txt_file);
				foreach($lines as $line){
					if(!$line)continue;
					$rows_latest        = explode("|", $line);
					if($rows_latest[0] == "0"){
						$objectv['versions']++;
						$rows_completed = explode("|", $line);
					}
				}
    			if($objectv['running'] == "N/A" ){
    				if($rows_latest[0] == "0"){
    					$objectv['running'] = "Completed";
    				}else{
    					if($rows_latest[0] != "")$objectv['running'] = "Error:".$rows_latest[0];
    				}
  				}
  				if($rows_completed[3])$objectv['lastcompleted'] = date('r', $rows_completed[3]);
			}

			// Modify result object.
			$objectv['enable'] = boolval($objectv['enable']);
			$wdays = array('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Daily');
			$objectv['schedule'] = $wdays[$objectv['wday']]." ".$objectv['hour'].":".$objectv['minute'];
			if($objectv['retention'] == 0){
				$objectv['retention'] = "Single version";
			}
			if($objectv['retention'] == 1){
				$objectv['retention'] = $objectv['retention']." day";
			}
			if($objectv['retention'] > 1){
				$objectv['retention'] = $objectv['retention']." days";
			}
		}

		// Filter the result.
		return $this->applyFilter($objects, $params['start'],
		$params['limit'], $params['sortfield'], $params['sortdir']);
	}

	/**
	* get
	*/
	function get($params, $context) {
		global $xmlConfig;
		// Validate the RPC caller context.
		$this->validateMethodContext($context, array(
			"role" => OMV_ROLE_ADMINISTRATOR
		));
		// Validate the parameters of the RPC service method.
		$this->validateMethodParams($params, '{
		"type":"object",
		"properties":{
		"uuid":{'.$GLOBALS['OMV_JSONSCHEMA_UUID'].'}
		}
		}');
		// Get the configuration object.
		$xpath = sprintf("//services/sbackup/backuplist/backup[uuid='%s']",
		$params['uuid']);
		$object = $xmlConfig->get($xpath);
		if(is_null($object)) {
			throw new OMVException(OMVErrorMsg::E_CONFIG_GET_OBJECT_FAILED,
			$xpath);
		}
		// Modify result object.
		$object['enable'] = boolval($object['enable']);
		return $object;
	}

	/**
	* set
	*/
	function set($params, $context) {
		global $xmlConfig;
		// Validate the RPC caller context.
		$this->validateMethodContext($context, array(
		"role" => OMV_ROLE_ADMINISTRATOR
		));
		// Validate the parameters of the RPC service method.
		$this->validateMethodParams($params, '{
		"type":"object",
		"properties":{
		"uuid":{'.$GLOBALS['OMV_JSONSCHEMA_UUID_UNDEFINED'].'},
		"enable":{"type":"boolean"},
		"name":{"type":"string"},
		"sharedfoldersource":{'.$GLOBALS['OMV_JSONSCHEMA_UUID'].'},
		"sharedfoldertarget":{'.$GLOBALS['OMV_JSONSCHEMA_UUID'].'},
		"wday":{"type":"string"},
		"hour":{"type":"string"},
		"minute":{"type":"string"},
		"savelog":{"type":"boolean"},
		"retention":{"type":"integer","minimum":0,"maximum":365}
		}
		}');
		// Prepare the configuration object.
		$object = array(
		"uuid" => ($params['uuid'] == $GLOBALS['OMV_UUID_UNDEFINED']) ?
		OMVUtil::uuid() : $params['uuid'],
		"enable" => array_boolval($params, 'enable'),
		"name" => $params['name'],
		"sharedfoldersource" => $params['sharedfoldersource'],
		"sharedfoldertarget" => $params['sharedfoldertarget'],
		"wday" => $params['wday'],
		"hour" => $params['hour'],
		"minute" => $params['minute'],
		"savelog" => $params['savelog'],
		"retention" => $params['retention']
		);
		if($params['sharedfoldersource'] == $params['sharedfoldertarget']){
			throw new OMVException(OMVErrorMsg::E_MISC_FAILURE,"Source and destination targets cannot be the same.");
		}
		$xpath = "//services/sbackup/backuplist/backup";
		$objects = $xmlConfig->getList($xpath);
		if(is_null($objects)) {
			throw new OMVException(OMVErrorMsg::E_CONFIG_GET_OBJECT_FAILED,	$xpath);
		}
		
		// Add additional share informations.
		foreach($objects as $objectk => &$objectv) {

			// Get the shared folder configuration object.
			if($objectv['sharedfoldertarget'] == $params['sharedfoldersource']){
				throw new OMVException(OMVErrorMsg::E_MISC_FAILURE,"Backup source is set as destinations for another backup. Cannot be used.");
			}
		}
		
		// Set the configuration object.
		$success = FALSE;
		if($params['uuid'] == $GLOBALS['OMV_UUID_UNDEFINED']) {
			// Append object to configuration.
			$success = $xmlConfig->set("//services/sbackup/backuplist",
			array("backup" => $object));
		} else {
			// Update existing configuration object.
			$success = $xmlConfig->replace("//services/sbackup/backuplist/backup[" .
			"uuid='{$params['uuid']}']", $object);
		}
		if(FALSE === $success) {
			throw new OMVException(OMVErrorMsg::E_CONFIG_SET_OBJECT_FAILED);
		}
		// Notify configuration changes.
		$dispatcher = &OMVNotifyDispatcher::getInstance();
		$dispatcher->notify(($params['uuid'] == $GLOBALS['OMV_UUID_UNDEFINED']) ?
		OMV_NOTIFY_CREATE : OMV_NOTIFY_MODIFY,
		"org.openmediavault.services.sbackup.backuplist.backup", $object);
		// Return the configuration object.
		return $object;
	}

	/**
	* delete
	*/
	public function delete($params, $context) {
		// Validate the RPC caller context.
		$this->validateMethodContext($context, array(
		"role" => OMV_ROLE_ADMINISTRATOR
		));
		// Validate the parameters of the RPC service method.
		$this->validateMethodParams($params, '{
		"type":"object",
		"properties":{
		"uuid":{'.$GLOBALS['OMV_JSONSCHEMA_UUID'].'}
		}
		}');
		// Delete the configuration object.
		$xpath = sprintf("//services/sbackup/backuplist/backup[uuid='%s']",
		$params['uuid']);
		return $this->deleteConfigObjectByPath($xpath,
		"org.openmediavault.services.sbackup.backuplist.backup");
	}

	/**
	* runBackup
	*/
	public function runBackup($params, $context) {
		global $xmlConfig;
		// Validate the RPC caller context.
		$this->validateMethodContext($context, array(
		"role" => OMV_ROLE_ADMINISTRATOR
		));
		// Validate the parameters of the RPC service method.
		$this->validateMethodParams($params, '{
		"type":"object",
		"properties":{
		"uuid":{'.$GLOBALS['OMV_JSONSCHEMA_UUID'].'}
		}
		}');
		// Check if the module is marked as dirty. This can be an indication
		// that the samba recycle bin cron script has not been created or
		// updated until now.
		if($this->isModuleDirty("sbackup"))
		throw new OMVException(OMVErrorMsg::E_CONFIG_DIRTY);
		// Execute process.
		$cmd = "/usr/bin/at -f /var/lib/openmediavault/sbackup.d/backup_".$params['uuid']." now";
		if(0 !== $this->exec($cmd, $output)) {
			throw new OMVException(OMVErrorMsg::E_EXEC_FAILED,
			$cmd, implode("\n", $output));
		}
	}
	
	/**
	* runRestore
	*/
	public function runRestore($params, $context) {
		global $xmlConfig;
		// Validate the RPC caller context.
		$this->validateMethodContext($context, array(
		"role" => OMV_ROLE_ADMINISTRATOR
		));
		// Validate the parameters of the RPC service method.
		$this->validateMethodParams($params, '{
		"type":"object",
		"properties":{
		"uuid":{'.$GLOBALS['OMV_JSONSCHEMA_UUID'].'},
		"version":{"type":"string"},
		"dir":{"type":"string"},
		"savelog":{"type":"boolean"},
		"deleteold":{"type":"boolean"}
		}
		}');

		// Check if the module is marked as dirty. This can be an indication
		// that the samba recycle bin cron script has not been created or
		// updated until now.
		if($this->isModuleDirty("sbackup"))
		throw new OMVException(OMVErrorMsg::E_CONFIG_DIRTY);
		
		// Get the configuration object.
		$xpath = sprintf("//services/sbackup/backuplist/backup[uuid='%s']",$params['uuid']);
		$object = $xmlConfig->get($xpath);
		if(is_null($object)) {
			throw new OMVException(OMVErrorMsg::E_CONFIG_GET_OBJECT_FAILED,$xpath);
		}

		$xpath_tmp = sprintf("//system/shares/sharedfolder[uuid='%s']",$object['sharedfoldersource']);$object_tmp = $xmlConfig->get($xpath_tmp);if(is_null($object_tmp)){throw new OMVException(OMVErrorMsg::E_CONFIG_GET_OBJECT_FAILED,$xpath_tmp);}
		$GET_SOURCE_PATH = $object_tmp['reldirpath'];
		$xpath_tmp = sprintf("//system/fstab/mntent[uuid='%s']",$object_tmp['mntentref']);$object_tmp = $xmlConfig->get($xpath_tmp);if(is_null($object_tmp)){throw new OMVException(OMVErrorMsg::E_CONFIG_GET_OBJECT_FAILED,$xpath_tmp);}
		$GET_SOURCE_MNT = $object_tmp['dir'];
		$GET_SOURCE_PATH = $GET_SOURCE_MNT."/".$GET_SOURCE_PATH."/";
		
		$xpath_tmp = sprintf("//system/shares/sharedfolder[uuid='%s']",$object['sharedfoldertarget']);$object_tmp = $xmlConfig->get($xpath_tmp);if(is_null($object_tmp)){throw new OMVException(OMVErrorMsg::E_CONFIG_GET_OBJECT_FAILED,$xpath_tmp);}
		$GET_TARGET_PATH = $object_tmp['reldirpath'];
		$xpath_tmp = sprintf("//system/fstab/mntent[uuid='%s']",$object_tmp['mntentref']);$object_tmp = $xmlConfig->get($xpath_tmp);if(is_null($object_tmp)){throw new OMVException(OMVErrorMsg::E_CONFIG_GET_OBJECT_FAILED,$xpath_tmp);}
		$GET_TARGET_MNT = $object_tmp['dir'];
		$GET_TARGET_PATH = $GET_TARGET_MNT."/".$GET_TARGET_PATH;
		$GET_TARGET_DEST = $GET_TARGET_PATH."/sbackup_".$params['uuid']."/";
		
		$GET_TARGET_DEST .= "/data_".$params['version']."/";
		
		if($params['dir']){
			$GET_SOURCE_PATH .= "/".$params['dir']."/";
			$GET_TARGET_DEST .= "/".$params['dir']."/";
		}

		if(!file_exists($GET_TARGET_DEST)){
			throw new OMVException(OMVErrorMsg::E_MISC_FAILURE,"Version \"".$params['version']."\" cannot be found.");
		}

		// Generate restore script.
		$OMV_SBACKUP_SESLOGDIR  = "/var/log/sbackup/sessionlogs";
		$OMV_SBACKUP_LOGFILE = "/var/log/sbackup/history_".$params['uuid'];
		$runfile="/var/run/sbackup_".$params['uuid'];
		$filename = "/var/lib/openmediavault/sbackup.d/restore_".$params['uuid'];
		$scriptfile = fopen($filename, "w");
		fwrite($scriptfile, "#!/bin/sh\n");
    fwrite($scriptfile, "# This configuration file is auto-generated.\n");
    fwrite($scriptfile, "# WARNING: Do not edit this file, your changes will be lost.\n");
    fwrite($scriptfile, ". /usr/share/openmediavault/scripts/helper-functions\n");
    fwrite($scriptfile, "SB_TIMESTART=\$(date +\"%s\")\n");
    fwrite($scriptfile, "cleanup() {\n");
    fwrite($scriptfile, "  omv_kill_children \$\$\n");
    fwrite($scriptfile, "  IFS='\n");
    fwrite($scriptfile, "'\n");
    fwrite($scriptfile, "  for line in `echo \"\$RSOUT\"`; do \n");
    fwrite($scriptfile, "    RSSIZE=\$(echo \${line}|awk '/^total size is / {print \$4}')\n");
    fwrite($scriptfile, "    RSPERF=\$(echo \${line}|awk '/^total size is / {print \$7}')\n");
    fwrite($scriptfile, "  done\n");
    fwrite($scriptfile, "  SB_TIMEEND=\$(date +\"%s\")\n");
    fwrite($scriptfile, "  if [ \"\${SB_ECODE}\" = \"\" ]; then\n");
    fwrite($scriptfile, "    SB_ECODE=-1\n");
    fwrite($scriptfile, "  fi\n");
		fwrite($scriptfile, "  cat \"".$OMV_SBACKUP_LOGFILE."\"|sed \"s/^running|\(.*\)|\(.*\)|\${SB_TIMESTART}||||restore|/\${SB_ECODE}|\\1|\\2|\${SB_TIMESTART}|\${SB_TIMEEND}|\${RSSIZE}|\${RSPERF}|restore|/g\" > \"".$OMV_SBACKUP_LOGFILE.".new\"\n");
    fwrite($scriptfile, "  mv \"".$OMV_SBACKUP_LOGFILE.".new\" \"".$OMV_SBACKUP_LOGFILE."\"\n");
		if($params['savelog'])fwrite($scriptfile, "  echo \"Backup name: ".$object['name']."\nUUID: ".$params['uuid']."\n\n\$RSOUT\n\nStart time: \$(date -d @\${SB_TIMESTART})\nEnd time: \$(date -d @\${SB_TIMEEND})\nStatus: \${SB_ECODE}\" > \"".$OMV_SBACKUP_SESLOGDIR."/".$params['uuid']."_\${SB_TIMESTART}.log\"\n");
    fwrite($scriptfile, "  rm -f \"".$runfile."\"\n");
    fwrite($scriptfile, "  exit 0\n");
    fwrite($scriptfile, "}\n");
    fwrite($scriptfile, "# Check if backup is already running.\n");
    fwrite($scriptfile, "[ -e \"".$runfile."\" ] && exit 1\n");
    fwrite($scriptfile, "# Check if all filesystems are mounted.\n");
    fwrite($scriptfile, "if ! omv_is_mounted \"".$GET_SOURCE_MNT."\" ; then\n");
		fwrite($scriptfile, "  echo \"Source not mounted|".$object['name']."|".$params['uuid']."|\${SB_TIMESTART}||||restore|\" >> \"".$OMV_SBACKUP_LOGFILE."\"\n");
    fwrite($scriptfile, "  exit 1\n");
    fwrite($scriptfile, "fi\n");
    fwrite($scriptfile, "if ! omv_is_mounted \"".$GET_TARGET_MNT."\" ; then\n");
    fwrite($scriptfile, "  echo \"Target not mounted|".$object['name']."|".$params['uuid']."|\${SB_TIMESTART}||||restore|\" >> \"".$OMV_SBACKUP_LOGFILE."\"\n");
    fwrite($scriptfile, "  exit 1\n");
    fwrite($scriptfile, "fi\n");
    fwrite($scriptfile, "trap cleanup 0 1 2 5 9 15\n");
    fwrite($scriptfile, "echo \"restore|\" > \"".$runfile."\"\n");
    fwrite($scriptfile, "# Create target directory.\n");
    fwrite($scriptfile, "mkdir -p \"".$GET_SOURCE_PATH."\"\n");
    fwrite($scriptfile, "echo \"running|".$object['name']."|".$params['uuid']."|\${SB_TIMESTART}||||restore|\" >> \"".$OMV_SBACKUP_LOGFILE."\"\n");
    fwrite($scriptfile, "RSOUT=\$(rsync --verbose -aEAX");
    if($params['deleteold'])fwrite($scriptfile, " --delete");
    fwrite($scriptfile, " \"".$GET_TARGET_DEST."\" \"".$GET_SOURCE_PATH."\" 2>&1)\n");
    fwrite($scriptfile, "SB_ECODE=\$(echo \$?)\n sleep 5");
		fclose($scriptfile);
		
		$cmd = "chmod 755 \"$filename\"";
		if(0 !== $this->exec($cmd, $output)) {
			throw new OMVException(OMVErrorMsg::E_EXEC_FAILED,
			$cmd, implode("\n", $output));
		}
		// Execute process.
		$cmd = "/usr/bin/at -f ".$filename." now";
		if(0 !== $this->exec($cmd, $output)) {
			throw new OMVException(OMVErrorMsg::E_EXEC_FAILED,
			$cmd, implode("\n", $output));
		}
	}
	
	/**
	* getRestoreDirBrowser
	*/
  public function getRestoreDirBrowser($params, $context) {
    global $xmlConfig;
    // Validate the RPC caller context.
    $this->validateMethodContext($context, array(
       "role" => OMV_ROLE_ADMINISTRATOR
      ));
    if(!$params['version'])return;
    // Validate the parameters of the RPC service method.
    $this->validateMethodParams($params, '{
       "type":"object",
       "properties":{
        "uuid":{'.$GLOBALS['OMV_JSONSCHEMA_UUID'].'},
        "backupuuid":{'.$GLOBALS['OMV_JSONSCHEMA_UUID'].'},
        "version":{"type":"string"},
        "path":{"type":"string"}
       }
      }');
    // The field 'path' may not contain the characters '..'.
    if (1 == preg_match("/\.\./", $params['path'])) {
     throw new OMVException(OMVErrorMsg::E_RPC_SERVICE_INVALID_PARAM,
       sprintf(gettext("The field '%s' contains forbidden ".
       "two-dot symbols"), "path"));
    }
    // Get the absolute shared folder path.
    $rootPath = OMVRpc::exec("ShareMgmt", "getPath", array("uuid" => $params['uuid']), $context);
     
    // List the directory contents.
    $result = array();
    $path = sprintf("%s/%s", $rootPath.$params['version'], rtrim($params['path'], "/"));
    
    foreach (new DirectoryIterator($path) as $item) {
     if ($item->isDot())
      continue;
     if (!$item->isDir())
      continue;
     $result[] = $item->getFilename();
    }
    return $result;
  }
  
	/**
	* showLog
	*/
	public function showLog($params, $context) {
		// Validate the RPC caller context.
		$this->validateMethodContext($context, array(
		"role" => OMV_ROLE_ADMINISTRATOR
		));
		if(file_exists("/var/log/sbackup/sessionlogs/".$params['fileid'].".log")){
			// Create a background process.
			$bgStatusFilename = $this->createBgProcStatus();
			$pid = $this->fork();
			if($pid > 0) { // Parent process.
				$this->initializeBgProcStatus($bgStatusFilename, $pid);
				return $bgStatusFilename;
			}
			// Child process.
			try {
				$bgOutputFilename = $this->createBgProcOutput();
				$this->updateBgProcStatus($bgStatusFilename, "outputfilename",
				$bgOutputFilename);
				// Execute the backup script.
				$cmd = "/bin/cat";
				$cmdArgs = array("/var/log/sbackup/sessionlogs/".$params['fileid'].".log");
				if(FALSE === $this->execve($cmd, $cmdArgs, $bgOutputFilename)) {
					throw new OMVException(OMVErrorMsg::E_EXEC_FAILED,
					$cmd." ".implode(" ", $cmdArgs), "");
				}
			} catch(Exception $e) {
				$this->finalizeBgProcStatus($bgStatusFilename, "", $e);
				exit(1);
			}
		}
	}

	/**
	* getSettings
	*/
  public function getSettings($params, $context) {
  	global $xmlConfig;
  	$this->validateMethodContext($context, array("role" => OMV_ROLE_ADMINISTRATOR));
  	$xpath = "//services/sbackup/settings";
    $object = $xmlConfig->get($xpath);
    if(is_null($object)) {
       throw new OMVException(OMVErrorMsg::E_CONFIG_GET_OBJECT_FAILED,$xpath);
    }
    
    $object['backuplogretention'] = intval($object['backuplogretention']);
    $object['sessionlogretention'] = intval($object['sessionlogretention']);

    return $object;
  }
  
  /**
	* setSettings
	*/
  public function setSettings($params, $context) {
  	global $xmlConfig;
    $this->validateMethodContext($context, array("role" => OMV_ROLE_ADMINISTRATOR)); 
    $this->validateMethodParams($params, '{
      "type":"object",
      "properties":{
        "backuplogretention":{"type":"integer","minimum":0,"maximum":365},
        "sessionlogretention":{"type":"integer","minimum":0,"maximum":365}
        }
      }'
    );
    
    if($params['backuplogretention'] < $params['sessionlogretention']){
    	throw new OMVException(OMVErrorMsg::E_MISC_FAILURE,"Log retention cannot be longer then history retention.");
    }
    
    // Get the existing configuration object.
    $xpath = "//services/sbackup/settings";
    $oldObject = $xmlConfig->get($xpath);
    if(is_null($oldObject)) {
       throw new OMVException(OMVErrorMsg::E_CONFIG_GET_OBJECT_FAILED,$xpath);
    }
 
    // Update the configuration object.
    $object = array(
      "backuplogretention" => $params['backuplogretention'],
      "sessionlogretention" => $params['sessionlogretention']
    );

    // Update the xmlConfig file. If it fails then generate an error
    
    if(FALSE === $xmlConfig->replace("//services/sbackup/settings", $object)) {
        throw new OMVException(OMVErrorMsg::E_CONFIG_SET_OBJECT_FAILED);
    }

    // Notify configuration changes.
    $dispatcher = &OMVNotifyDispatcher::getInstance();
    $dispatcher->notify(OMV_NOTIFY_MODIFY, "org.openmediavault.services.sbackup.settings", $object);

    // Return the configuration object.
    return $object;
  }
  
  /**
	* getVersions
	*/
  public function getVersions($params, $context) {
  	global $xmlConfig;
  	// Validate the RPC caller context.
  	$this->validateMethodContext($context, array(
  	"role" => OMV_ROLE_ADMINISTRATOR
  	));
		$this->validateMethodParams($params, '{
		"type":"object",
		"properties":{
		"uuid":{'.$GLOBALS['OMV_JSONSCHEMA_UUID'].'}
		}
		}');
  	
  	// Prepare the result list.
  	$result = array();
  	
		if(file_exists("/var/log/sbackup/history_".$params['uuid'])){
			$txt_file = file_get_contents("/var/log/sbackup/history_".$params['uuid']);
			$lines    = explode("\n", $txt_file);
			foreach($lines as $line){
				if(!$line)continue;
				$rows = explode("|", $line);
				if($rows[0] != "0" || $rows[7] != "backup")continue;
  			$result[] = array(
  				"version" => $rows[3],
  				"version_human" => date('r', $rows[3])
  			);
				
			}
		}
  	return $result;
  }

}

// Register the RPC service.
$rpcServiceMgr = &OMVRpcServiceMgr::getInstance(); // Get the "root" instance for the Services
$rpcServiceMgr->registerService(new OMVRpcServiceSBackup()); // Register a new instance of the RPC service described above
?>
