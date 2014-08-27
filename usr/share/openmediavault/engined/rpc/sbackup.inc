<?php
//class OMVRpcServiceSBackup extends OMVRpcServiceAbstract {
//	public function getName() { return "SBackup";} // RPC Service name. Same as in .js files
//	/* Initialize the RPC service. Different methods of the RPC service are declared here*/
//	public function initialize() {
//		$this->registerMethod("getbackuplist"); // Method name. Same as in .js files
//		$this->registerMethod("setbackuplist"); // Method name. Same as in .js files
//	}
//	public function getbackuplist($params, $context) {
//		// Reference to the global declaration of the variable $xmlConfig (Needed always)
//		global $xmlConfig;
//		// Validate the RPC caller context.
//		// This is used to check that only the admin can use this function
//		// Extra security as usermanagement is also done in the web interface
//		$this->validateMethodContext($context, array("role" => OMV_ROLE_ADMINISTRATOR));
//		// The $context contains the fields username and role
//		// Role can also be "OMV_ROLE_USER" or "OMV_ROLE_EVERYONE" (user and admin)
//		// Get the configuration object.
//		$xpath = "//services/sbackup"; // Structure of the xml schema
//		$object = $xmlConfig->get($xpath); // Read data from the xmlConfig file
//		// If no data is found then create an error
//		if(is_null($object)) {
//			throw new OMVException(OMVErrorMsg::E_CONFIG_GET_OBJECT_FAILED,$xpath);
//		}
//		// Modify the result object. (Change characters to values)
//		$object['enable'] = boolval($object['enable']);
//		$object['numberfield1'] = intval($object['numberfield1']);
//		return $object;
//	}
//	//*****************************************************************
//	//*****************************************************************
//	//*****************************************************************
//	public function setbackuplist($params, $context) {
//		// Check comments from getSettings
//		global $xmlConfig;
//		$this->validateMethodContext($context, array("role" => OMV_ROLE_ADMINISTRATOR));
//		// Validate the parameters of the RPC service method.
//		// Parameters are a JSON schema
//		// Possible types:
//		// boolean (only checks if variable is boolean)
//		// integer (same as number but with checking that value is integer)
//		// number
//		// minimum (<)
//		// maximum (>)
//		// exclusiveMinimum (<=)
//		// exclusiveMaximum (>=)
//		// enum (enumeration, multiple enum definitions can be made)
//		// maxDecimal (type is float and amount of decimals <=)
//		// string
//		// minLength (string cannot be shorter than this)
//		// maxLength (string cannot be longer than this)
//		// format (in the source most of the format checks are commented out)
//		// regex (pattern)
//		// uri (Requires the URL to contain a query string)
//		// email (Requires the input be validated as an email)
//		// ip-address (Requires the input be validated as an IPV4 address)
//		// ipv6 (Requires the input be validated as an IPV6 address)
//		// enum (enumeration)
//		// array (array items are checked like regular variable types)
//		// items (an array must have items)
//		// minItems (an array must have more items than this)
//		// maxItems (an array must have less items than this)
//		// object (see below how to use)
//		// null (has to be null)
//		// any (Always returns valid)
//		$this->validateMethodParams($params, '{
//		"type":"object",
//		"properties":{
//		"enable":{"type":"boolean"},
//		"numberfield1":{"type":"integer","minimum":1,"maximum":65535}
//		}
//		}'
//		);
//		// Get the existing configuration object.
//		$xpath = "//services/sbackup"; // Structure of the xml schema
//		$oldObject = $xmlConfig->get($xpath); // Read data from the xmlConfig file
//		// If no data is found then create an error
//		if(is_null($oldObject)) {
//			throw new OMVException(OMVErrorMsg::E_CONFIG_GET_OBJECT_FAILED,$xpath);
//		}
//		// Update the configuration object.
//		$object = array(
//		"enable" => array_boolval($params, 'enable'),
//		"numberfield1" => $params['numberfield1'],
//		);
//		// Update the xmlConfig file. If it fails then generate an error
//		if(FALSE === $xmlConfig->replace("//services/sbackup", $object)) {
//			throw new OMVException(OMVErrorMsg::E_CONFIG_SET_OBJECT_FAILED);
//		}
//		// Notify configuration changes.
//		$dispatcher = &OMVNotifyDispatcher::getInstance();
//		$dispatcher->notify(OMV_NOTIFY_MODIFY, "org.openmediavault.services.sbackup", $object);
//		// Return the configuration object.
//		return $object;
//	}
//}

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
                $this->registerMethod("getList");
                $this->registerMethod("get");
                $this->registerMethod("set");
                $this->registerMethod("delete");
                //$this->registerMethod("execute");
        }

        /**
         * Get list of USB backup job configuration objects.
         * @param data An array containing the following fields:
         *   \em start The index where to start.
         *   \em limit The number of objects to process.
         *   \em sortfield The name of the column used to sort.
         *   \em sortdir The sort direction, ASC or DESC.
         * @return An array containing the requested objects. The field \em total
         *   contains the total number of objects, \em data contains the object
         *   array. An exception will be thrown in case of an error.
         * @throw E_CONFIG_GET_OBJECT_FAILED
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
                        if($objectv['running'] == "N/A" && file_exists(sprintf("/var/lib/openmediavault/sbackup.d/laststatus-%s", $objectv['uuid']))){
                        	$txt_file    = file_get_contents(sprintf("/var/lib/openmediavault/sbackup.d/laststatus-%s", $objectv['uuid']));
													$rows        = explode("|", $txt_file);
                        	if($rows[2] == "0"){
                        		$objectv['running'] = "Completed";
                        	}else{
                        		$objectv['running'] = "Error:".$rows[2];
                        	}
                        	$objectv['lastcompleted'] = date('r', $rows[1]);
                        }
                        
                        // Get last completed job
                        if($objectv['lastcompleted'] != "N/A" && file_exists(sprintf("/var/lib/openmediavault/sbackup.d/lastcompleted-%s", $objectv['uuid']))){
                        	$txt_file           = file_get_contents(sprintf("/var/lib/openmediavault/sbackup.d/lastcompleted-%s", $objectv['uuid']));
													$rows               = explode("|", $txt_file);
													$objectv['lastcompleted'] = date('r', $rows[1]);
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
         * Get a USB backup job configuration object.
         * @param params An array containing the following fields:
         *   \em uuid The UUID of the configuration object.
         * @param context The context of the caller.
         * @return The requested configuration object.
         * @throw E_CONFIG_GET_OBJECT_FAILED
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
         * Set a USB backup job configuration object.
         * @param params The method parameters.
         * @param context The context of the caller.
         * @return The stored configuration object.
         * @throw E_CONFIG_OBJECT_UNIQUENESS
         * @throw E_CONFIG_SET_OBJECT_FAILED
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
                                  "minute":{"type":"string"}
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
                        "minute" => $params['minute']
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
         * Delete a backup job configuration object.
         * @param params An array containing the following fields:
         *   \em uuid The UUID of the configuration object.
         * @param context The context of the caller.
         * @return The deleted configuration object.
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
}

// Register the RPC service.
$rpcServiceMgr = &OMVRpcServiceMgr::getInstance(); // Get the "root" instance for the Services
$rpcServiceMgr->registerService(new OMVRpcServiceSBackup()); // Register a new instance of the RPC service described above
?>
