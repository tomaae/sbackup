<?php
require_once("openmediavault/object.inc");
require_once("openmediavault/config.inc");
require_once("openmediavault/error.inc");
require_once("openmediavault/rpcservice.inc");
require_once("openmediavault/notify.inc");

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
                //$this->registerMethod("execute");
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
                  
        	 			if(file_exists("/var/log/sbackup/backup.log")){
        	 				$i=0;
        	 				$txt_file = file_get_contents("/var/log/sbackup/backup.log");
        	 				$lines    = explode("\n", $txt_file);
        	 				foreach($lines as $line){
        	 					if(!$line)continue;
    								$rows = explode("|", $line);
    								$objects[$i]['id'] = $i;
    								$objects[$i]['uuid'] = $rows[1];
    								if($rows[0]){$objects[$i]['name'] = $rows[0];}else{$objects[$i]['name'] = "N/A";}
                  	if($rows[4] == "0"){
                  		$objects[$i]['running'] = "Completed";
                  	}else{
                  		$objects[$i]['running'] = "Error:".$rows[4];
                  	}
    								if($rows[2]){$objects[$i]['starttime'] = date('r', $rows[2]);}else{$objects[$i]['starttime'] = "N/A";}
    								if($rows[3]){$objects[$i]['endtime'] = date('r', $rows[3]);}else{$objects[$i]['endtime'] = "N/A";}
    								if($rows[5] != ""){$objects[$i]['backupsize'] = $rows[5];}else{$objects[$i]['backupsize'] = "N/A";}
    								if(file_exists("/var/log/sbackup/sessionlogs/".$objects[$i]['name']."_".$objects[$i]['uuid']."_".$rows[2].".log")){
    									$objects[$i]['haslog'] = "yes";
    									$objects[$i]['fileid'] = $objects[$i]['name']."_".$objects[$i]['uuid']."_".$rows[2];
    								}else{
    									$objects[$i]['haslog'] = "no";
    								}
    								$i++;
    							}
                }
                // Filter the result.
                return $this->applyFilter($objects, $params['start'],
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
                        if(file_exists(sprintf("/var/run/sbackup-%s", $objectv['uuid']))){$objectv['running'] = "Running";}
                        if($objectv['running'] == "N/A" && file_exists(sprintf("/var/log/sbackup/sessionstatus/laststatus-%s", $objectv['uuid']))){
                        	$txt_file    = file_get_contents(sprintf("/var/log/sbackup/sessionstatus/laststatus-%s", $objectv['uuid']));
													$rows        = explode("|", $txt_file);
                        	if($rows[2] == "0"){
                        		$objectv['running'] = "Completed";
                        	}else{
                        		if($rows[2] != "")$objectv['running'] = "Error:".$rows[2];
                        	}
                        	if($rows[1])$objectv['lastcompleted'] = date('r', $rows[1]);
                        }
                        
                        // Get last completed job
                        if($objectv['lastcompleted'] != "N/A" && file_exists(sprintf("/var/log/sbackup/sessionstatus/lastcompleted-%s", $objectv['uuid']))){
                        	$txt_file           = file_get_contents(sprintf("/var/log/sbackup/sessionstatus/lastcompleted-%s", $objectv['uuid']));
													$rows               = explode("|", $txt_file);
													if($rows[1])$objectv['lastcompleted'] = date('r', $rows[1]);
                        }
                        // Modify result object.
                        $objectv['enable'] = boolval($objectv['enable']);
                        $wdays = array('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Daily');
                        $objectv['schedule'] = $wdays[$objectv['wday']]." ".$objectv['hour'].":".$objectv['minute'];
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
                                  "savelog":{"type":"boolean"}
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
                        "savelog" => $params['savelog']
                );
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
         * Execute a backup job.
         * @param params An array containing the following fields:
         *   \em uuid The UUID of the cron job to execute.
         * @param context The context of the caller.
         * @return The name of the background process status file.
         * @throw E_CONFIG_DIRTY
         */
//        public function execute($params, $context) {
//                // Validate the RPC caller context.
//                $this->validateMethodContext($context, array(
//                          "role" => OMV_ROLE_ADMINISTRATOR
//                  ));
//                // Validate the parameters of the RPC service method.
//                $this->validateMethodParams($params, '{
//                          "type":"object",
//                          "properties":{
//                                  "uuid":{'.$GLOBALS['OMV_JSONSCHEMA_UUID'].'}
//                          }
//                  }');
//                // Check if the module is marked as dirty. This is an indication
//                // that the rsync cron script has not been created or updated
//                // until now.
//                if($this->isModuleDirty("sbackup")) {
//                        throw new OMVException(OMVErrorMsg::E_CONFIG_DIRTY);
//                }
//                // Create a background process.
//                $bgStatusFilename = $this->createBgProcStatus();
//                $pid = $this->fork();
//                if($pid > 0) { // Parent process.
//                        $this->initializeBgProcStatus($bgStatusFilename, $pid);
//                        return $bgStatusFilename;
//                }
//                // Child process.
//                try {
//                        $bgOutputFilename = $this->createBgProcOutput();
//                        $this->updateBgProcStatus($bgStatusFilename, "outputfilename",
//                          $bgOutputFilename);
//                        // Execute the backup script.
//                        $cmd = "/bin/sh";
//                        $cmdArgs = array(sprintf("%s/rsync-%s",
//                          $GLOBALS['OMV_USBBACKUP_SCRIPTS_DIR'], $params['uuid']));
//                        if(FALSE === $this->execve($cmd, $cmdArgs, $bgOutputFilename)) {
//                                throw new OMVException(OMVErrorMsg::E_EXEC_FAILED,
//                                  $cmd." ".implode(" ", $cmdArgs), "");
//                        }
//                } catch(Exception $e) {
//                        $this->finalizeBgProcStatus($bgStatusFilename, "", $e);
//                        exit(1);
//                }
//        }

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
}

// Register the RPC service.
$rpcServiceMgr = &OMVRpcServiceMgr::getInstance(); // Get the "root" instance for the Services
$rpcServiceMgr->registerService(new OMVRpcServiceSBackup()); // Register a new instance of the RPC service described above
?>
