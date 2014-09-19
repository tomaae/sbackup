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
		$this->registerMethod("abortBackup");
		$this->registerMethod("runPurge");
		$this->registerMethod("runRestore");
		$this->registerMethod("getRestoreDirBrowser");
		$this->registerMethod("getVersions");
		$this->registerMethod("getJobList");
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
  					$t_objects[$i]['job_status'] = "Completed";
  				}else{
  					$t_objects[$i]['job_status'] = "Error:".$rows[0];
  				}
  				if($rows[0] == "running"){
  					$t_objects[$i]['job_status'] = "Running";
  				}
  				if($rows[3]){$t_objects[$i]['starttime'] = date('r', $rows[3]);}else{$t_objects[$i]['starttime'] = "N/A";}
  				if($rows[4]){$t_objects[$i]['endtime'] = date('r', $rows[4]);}else{$t_objects[$i]['endtime'] = "N/A";}
  				if($rows[7] == "backup" || $rows[7] == "copy"){
    				if($rows[5] != ""){
    					if($rows[5] > 0){
    					$t_objects[$i]['backupsize'] = $rows[5]." B";
      					if($rows[5] > (100 * 1024)) $t_objects[$i]['backupsize'] = ceil($rows[5] / 1024)." KiB";
      					if($rows[5] > (9 * 1024 * 1024)) $t_objects[$i]['backupsize'] = ceil($rows[5] / 1024 / 1024)." MiB";
      					if($rows[5] > (9 * 1024 * 1024 * 1024)) $t_objects[$i]['backupsize'] = ceil($rows[5] / 1024 / 1024 / 1024)." GiB";
    					}else{$t_objects[$i]['backupsize'] = 0;}
    				}else{$t_objects[$i]['backupsize'] = "N/A";}
    				if($rows[6]){$t_objects[$i]['backupperf'] = $rows[6];}else{$t_objects[$i]['backupperf'] = "N/A";}
  				}else{$t_objects[$i]['backupsize'] = "N/A";$t_objects[$i]['backupperf'] = "N/A";}
  				if(file_exists("/var/log/sbackup/sessionlogs/".$objectv['uuid']."_".$rows[3].".log")){
  					$t_objects[$i]['haslog'] = "yes";
  					$t_objects[$i]['fileid'] = $objectv['uuid']."_".$rows[3];
  				}else{
  					$t_objects[$i]['haslog'] = "no";
  				}
    			$t_objects[$i]['job_type'] = "Backup";#"N/A";
  				if($rows[7] == "backup")$t_objects[$i]['job_type'] = "Backup";
  				if($rows[7] == "restore")$t_objects[$i]['job_type'] = "Restore";
  				if($rows[7] == "purge")$t_objects[$i]['job_type'] = "Purge";
					if($rows[7] == "migration")$t_objects[$i]['job_type'] = "Migration";
					if($rows[7] == "copy")$t_objects[$i]['job_type'] = "Copy";
  				if($rows[7] == "verify")$t_objects[$i]['job_type'] = "Verify";
  				
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
			$objectv['source_name'] = gettext("N/A");
			$sfobject = $xmlConfig->get("//system/shares/sharedfolder[uuid='{$objectv['source_sharedfolder_uuid']}']");
			if(!is_null($sfobject) && !empty($sfobject)) {
				$objectv['source_name'] = "S: ".$sfobject['name'];
			}

			// Get the shared folder configuration object.
			$objectv['target_name'] = gettext("N/A");
			$sfobject = $xmlConfig->get("//system/shares/sharedfolder[uuid='{$objectv['target_sharedfolder_uuid']}']");
			if(!is_null($sfobject) && !empty($sfobject)) {
				$objectv['target_name'] = "S: ".$sfobject['name'];
			}
			
			// Changes for purge/verify jobs
			$use_uuid = $objectv['uuid'];
			if($objectv['job_type'] == "purge"){
				$use_uuid = $objectv['purge_job_uuid'];
				$xpath_post = sprintf("//services/sbackup/backuplist/backup[uuid='%s']",$use_uuid);
  			$object_post = $xmlConfig->get($xpath_post);
  			if(is_null($object_post)) {throw new OMVException(OMVErrorMsg::E_CONFIG_GET_OBJECT_FAILED,$xpath_post);}
				$objectv['source_name'] = "B: ".$object_post['name'];
			}
			if($objectv['job_type'] == "verify"){
				$use_uuid = $objectv['verify_job_uuid'];
				$xpath_post = sprintf("//services/sbackup/backuplist/backup[uuid='%s']",$use_uuid);
  			$object_post = $xmlConfig->get($xpath_post);
  			if(is_null($object_post)) {throw new OMVException(OMVErrorMsg::E_CONFIG_GET_OBJECT_FAILED,$xpath_post);}
				$objectv['source_name'] = "B: ".$object_post['name'];
			}
			
			// Get last job status
			$objectv['job_status'] = "N/A";
			$objectv['lastcompleted'] = "N/A";
			if(file_exists(sprintf("/var/run/sbackup_%s", $use_uuid))){
				$txt_file           = file_get_contents(sprintf("/var/run/sbackup_%s", $use_uuid));
				$rows               = explode("|", $txt_file);
				if($rows[0] == "backup")$objectv['job_status']    = "Running";
				if($rows[0] == "restore")$objectv['job_status']   = "Restoring";
				if($rows[0] == "purge")$objectv['job_status']     = "Purging";
				if($rows[0] == "migration")$objectv['job_status'] = "Migrating";
				if($rows[0] == "copy")$objectv['job_status']      = "Copying";
			}
			$objectv['versions'] = 0;
			$objectv['size']     = 0;
			if(file_exists(sprintf("/var/log/sbackup/history_%s", $use_uuid))){
				$txt_file = file_get_contents(sprintf("/var/log/sbackup/history_%s", $use_uuid));
				$lines    = explode("\n", $txt_file);
				$rows_latest = array();
				$rows_completed = array();
				foreach($lines as $line){
					if(!$line)continue;
					$rows_current        = explode("|", $line);
					if($rows_current[7] != $objectv['job_type'])continue;
					$rows_latest = $rows_current;
					if($rows_current[0] == "0"){
						$objectv['versions']++;
						$objectv['size']+=$rows_current[5];
						$rows_completed = explode("|", $line);
					}
				}
    			if($objectv['job_status'] == "N/A" ){
    				if($rows_latest[0] == "0"){
    					$objectv['job_status'] = "Completed";
    				}else{
    					if($rows_latest[0] != "")$objectv['job_status'] = "Error:".$rows_latest[0];
    				}
  				}
  				if($rows_completed[3])$objectv['lastcompleted'] = date('r', $rows_completed[3]);
			}

			// Modify result object.
			if($objectv['job_type'] == "backup")  $objectv['job_type'] = "Backup";
			if($objectv['job_type'] == "restore") $objectv['job_type'] = "Restore";
			if($objectv['job_type'] == "copy")    $objectv['job_type'] = "Copy";
			if($objectv['job_type'] == "purge")   $objectv['job_type'] = "Purge";
			if($objectv['job_type'] == "verify")  $objectv['job_type'] = "Verify";
			
			$objectv['enable'] = boolval($objectv['enable']);
			$objectv['schedule'] = "";
		  if($objectv['schedule_enable'] == 0){
		  	$objectv['schedule'] = "Disabled";
		  }else{
		  	$objectv['schedule'] .= $objectv['schedule_hour'].":".$objectv['schedule_minute']." ";
		  	$val = explode(",", $objectv['schedule_wday']);
		  	if(count($val) == 7)$objectv['schedule'] .= "Daily";
		  	if(count($val) < 7){
		  		$wdays = array('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday');
      		if(count($val) > 1)$wdays = array('Sun','Mon','Tue','Wed','Thu','Fri','Sat');
      		if(count($val) > 3)$wdays = array('Su','Mo','Tu','We','Th','Fr','Sa');
      		if(count($val) > 4)$wdays = array('S','M','T','W','T','F','S');
      		for($i=0;$i < count($val);$i++){
      			$objectv['schedule'] .= $wdays[$val[$i]].",";
      		}
  				$objectv['schedule'] = trim($objectv['schedule'], ",");    		
				}
			}
			
			
			if($objectv['protect_days_job'] == 0){
				$objectv['retention'] = "Single version";
			}
			if($objectv['protect_days_job'] == 1){
				$objectv['retention'] = $objectv['protect_days_job']." day";
			}
			if($objectv['protect_days_job'] > 1){
				$objectv['retention'] = $objectv['protect_days_job']." days";
			}
			if($objectv['job_type'] == "Purge" || $objectv['job_type'] == "Verify"){
				$objectv['retention']        = "N/A";
				$objectv['versions']         = "N/A";
				$objectv['size']             = "N/A";
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
		$object['schedule_enable'] = boolval($object['schedule_enable']);
		$val = explode(",", $object['schedule_wday']);
		for($i=0;$i < count($val);$i++){
			if($val[$i] == 1)$object['schedule_mon'] = 1;
			if($val[$i] == 2)$object['schedule_tue'] = 1;
			if($val[$i] == 3)$object['schedule_wed'] = 1;
			if($val[$i] == 4)$object['schedule_thu'] = 1;
			if($val[$i] == 5)$object['schedule_fri'] = 1;
			if($val[$i] == 6)$object['schedule_sat'] = 1;
			if($val[$i] == 0)$object['schedule_sun'] = 1;
		}
		
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
		"job_type":{"type":"string"},
		"backup_type":{"type":"string"},
		"source_sharedfolder_uuid":{'.$GLOBALS['OMV_JSONSCHEMA_UUID'].'},
		"target_sharedfolder_uuid":{'.$GLOBALS['OMV_JSONSCHEMA_UUID'].'},
		"schedule_enable":{"type":"boolean"},
		"schedule_mon":{"type":"boolean"},
		"schedule_tue":{"type":"boolean"},
		"schedule_wed":{"type":"boolean"},
		"schedule_thu":{"type":"boolean"},
		"schedule_fri":{"type":"boolean"},
		"schedule_sat":{"type":"boolean"},
		"schedule_sun":{"type":"boolean"},
		"schedule_hour":{"type":"string"},
		"schedule_minute":{"type":"string"},
		"lvmsnap_enable":{"type":"boolean"},
		"lvmsnap_size":{"type":"integer","minimum":10,"maximum":100},
		"lvmsnap_fallback":{"type":"boolean"},
		"queue":{"type":"boolean"},
		"autorestart":{"type":"boolean"},
		"report":{"type":"boolean"},
		"post_purge":{"type":"boolean"},
		"protect_days_job":{"type":"integer","minimum":0,"maximum":365},
		"post_job":{"type":"string"},
		"purge_job_uuid":{"type":"string"},
		"verify_job_uuid":{"type":"string"}
		}
		}');
		
		if($params['schedule_enable'] == "1"){
			if($params['schedule_mon'] == "0" && $params['schedule_tue'] == "0" && $params['schedule_wed'] == "0" && $params['schedule_thu'] == "0" && $params['schedule_fri'] == "0" && $params['schedule_sat'] == "0" && $params['schedule_sun'] == "0")
			  throw new OMVException(OMVErrorMsg::E_MISC_FAILURE,"Schedule enabled but no day set.");
		}
		$params['schedule_wday'] = "";
		if($params['schedule_mon'])$params['schedule_wday'] .= "1,";
		if($params['schedule_tue'])$params['schedule_wday'] .= "2,";
		if($params['schedule_wed'])$params['schedule_wday'] .= "3,";
		if($params['schedule_thu'])$params['schedule_wday'] .= "4,";
		if($params['schedule_fri'])$params['schedule_wday'] .= "5,";
		if($params['schedule_sat'])$params['schedule_wday'] .= "6,";
		if($params['schedule_sun'])$params['schedule_wday'] .= "0,";
		
		// Prepare the configuration object.
		$object = array(
		"uuid" => ($params['uuid'] == $GLOBALS['OMV_UUID_UNDEFINED']) ?
		OMVUtil::uuid() : $params['uuid'],
		"enable" => array_boolval($params, 'enable'),
		"name" => $params['name'],
		"job_type" => $params['job_type'],
		"backup_type" => $params['backup_type'],
		"source_sharedfolder_uuid" => $params['source_sharedfolder_uuid'],
		"target_sharedfolder_uuid" => $params['target_sharedfolder_uuid'],
		"schedule_enable" => $params['schedule_enable'],
		"schedule_wday" => trim($params['schedule_wday'], ","),
		"schedule_hour" => $params['schedule_hour'],
		"schedule_minute" => $params['schedule_minute'],
		"lvmsnap_enable" => $params['lvmsnap_enable'],
		"lvmsnap_fallback" => $params['lvmsnap_fallback'],
		"lvmsnap_size" => $params['lvmsnap_size'],
		"queue" => $params['queue'],
		"autorestart" => $params['autorestart'],
		"report" => $params['report'],
		"post_purge" => $params['post_purge'],
		"protect_days_job" => $params['protect_days_job'],
		"post_job" => $params['post_job'],
		"purge_job_uuid" => $params['purge_job_uuid'],
		"verify_job_uuid" => $params['verify_job_uuid']
		);
		if($params['source_sharedfolder_uuid'] && $params['source_sharedfolder_uuid'] == $params['target_sharedfolder_uuid']){
			throw new OMVException(OMVErrorMsg::E_MISC_FAILURE,"Source and destination targets cannot be the same.");
		}
		
		if($params['post_job'] != ""){
  		$xpath_post = sprintf("//services/sbackup/backuplist/backup[uuid='%s']",$params['post_job']);
  		$object_post = $xmlConfig->get($xpath_post);
  		if(is_null($object_post)) {throw new OMVException(OMVErrorMsg::E_CONFIG_GET_OBJECT_FAILED,$xpath_post);}
  		while($object_post['post_job']){
  			if($object_post['post_job'] == $params['uuid']){
  				throw new OMVException(OMVErrorMsg::E_MISC_FAILURE,"Current post job cannot be set, it would create an infinite loop.");
  			}
  			$xpath_post = sprintf("//services/sbackup/backuplist/backup[uuid='%s']",$object_post['post_job']);
  			$object_post = $xmlConfig->get($xpath_post);
  			if(is_null($object_post)) {throw new OMVException(OMVErrorMsg::E_CONFIG_GET_OBJECT_FAILED,$xpath_post);}
  		}
		}
		
		
		$xpath = "//services/sbackup/backuplist/backup";
		$objects = $xmlConfig->getList($xpath);
		if(is_null($objects)) {
			throw new OMVException(OMVErrorMsg::E_CONFIG_GET_OBJECT_FAILED,	$xpath);
		}
		
		// Add additional share informations.
		foreach($objects as $objectk => &$objectv) {
			// Get the shared folder configuration object.
			if(($objectv['target_sharedfolder_uuid'] && $params['source_sharedfolder_uuid']) && ($objectv['target_sharedfolder_uuid'] == $params['source_sharedfolder_uuid'])){
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
		// Tests
		$xpath = "//services/sbackup/backuplist/backup";
		$objects = $xmlConfig->getList($xpath);
		if(is_null($objects)) {
			throw new OMVException(OMVErrorMsg::E_CONFIG_GET_OBJECT_FAILED,	$xpath);
		}
		
		foreach($objects as $objectk => &$objectv) {
			if($objectv['post_job'] && $objectv['post_job'] == $params['uuid'])throw new OMVException(OMVErrorMsg::E_MISC_FAILURE,"Job cannot be deleted, it is used as post job by \"".$objectv['name']."\"");
			if($objectv['job_type'] == "copy"   && $objectv['copy_job_uuid']   == $params['uuid'])throw new OMVException(OMVErrorMsg::E_MISC_FAILURE,"Job cannot be deleted, it does have copy job \"".$objectv['name']."\"");
			if($objectv['job_type'] == "purge"  && $objectv['purge_job_uuid']  == $params['uuid'])throw new OMVException(OMVErrorMsg::E_MISC_FAILURE,"Job cannot be deleted, it does have purge job \"".$objectv['name']."\"");
			if($objectv['job_type'] == "verify" && $objectv['verify_job_uuid'] == $params['uuid'])throw new OMVException(OMVErrorMsg::E_MISC_FAILURE,"Job cannot be deleted, it does have verify job \"".$objectv['name']."\"");
		}

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
		
		$xpath = sprintf("//services/sbackup/backuplist/backup[uuid='%s']",$params['uuid']);
  	$object = $xmlConfig->get($xpath);
  	
  	
  	$job_uuid = $params['uuid'];
		if($object['job_type'] == "backup") $job_type = "backup";
		if($object['job_type'] == "restore")$job_type = "restore";
		if($object['job_type'] == "purge")  $job_type = "purge";
		if($object['job_type'] == "copy")   $job_type = "backup";
		if($object['job_type'] == "verify") $job_type = "verify";
		
  	if($object['job_type'] == "purge")  $job_uuid = $object['purge_job_uuid'];
  	if($object['job_type'] == "verify") $job_uuid = $object['verify_job_uuid'];
  	
		// Execute process.
		$cmd = "/usr/bin/at -f /var/lib/openmediavault/sbackup.d/".$job_type."_".$job_uuid." now";
		if(0 !== $this->exec($cmd, $output)) {
			throw new OMVException(OMVErrorMsg::E_EXEC_FAILED,
			$cmd, implode("\n", $output));
		}
	}
	
	/**
	* abortBackup
	*/
	public function abortBackup($params, $context) {
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
		
		$runfile="/var/run/sbackup_".$params['uuid'];
		
		if(file_exists($runfile)){
			$txt_file = file_get_contents($runfile);
			$lines    = explode("\n", $txt_file);
			foreach($lines as $line){
				if(!$line)continue;
				$rows = explode("|", $line);
				if(is_numeric($rows[1]) && $rows[1] > 1){
      		// Execute process.
      		$cmd = ". /usr/share/openmediavault/scripts/helper-functions&&omv_kill_children ".$rows[1];
      		if(0 !== $this->exec($cmd, $output)) {
      			throw new OMVException(OMVErrorMsg::E_EXEC_FAILED,
      			$cmd, implode("\n", $output));
      		}
				}else{
					throw new OMVException(OMVErrorMsg::E_MISC_FAILURE,"Cannot find running backup.");
				}
			}
		}
  	

	}
	
	/**
	* runPurge
	*/
	public function runPurge($params, $context) {
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
		"retention":{"type":"integer"}
		}
		}');
		// Check if the module is marked as dirty. This can be an indication
		// that the samba recycle bin cron script has not been created or
		// updated until now.
		if($this->isModuleDirty("sbackup"))
		throw new OMVException(OMVErrorMsg::E_CONFIG_DIRTY);
		
		$xpath = sprintf("//services/sbackup/backuplist/backup[uuid='%s']",$params['uuid']);
  	$object = $xmlConfig->get($xpath);
  	
  	$job_uuid = $params['uuid'];
		if($object['job_type'] == "backup") $job_type = "backup";
		if($object['job_type'] == "restore")throw new OMVException(OMVErrorMsg::E_MISC_FAILURE,"Restore job cannot be purged");
		//if($object['job_type'] == "purge")  throw new OMVException(OMVErrorMsg::E_MISC_FAILURE,"Purge job cannot be purged");
		if($object['job_type'] == "copy")   $job_type = "backup";
		//if($object['job_type'] == "verify") throw new OMVException(OMVErrorMsg::E_MISC_FAILURE,"Verify job cannot be purged");
		
  	if($object['job_type'] == "purge")  $job_uuid = $object['purge_job_uuid'];
  	if($object['job_type'] == "verify") $job_uuid = $object['verify_job_uuid'];
  	
		// Execute process.
		//$cmd = "/usr/bin/at -f /var/lib/openmediavault/sbackup.d/purge_".$job_uuid." ".$params['retention']." now";
		$cmd = "echo /var/lib/openmediavault/sbackup.d/purge_".$job_uuid." ".$params['retention']."|/usr/bin/at now";
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
		"deleteold":{"type":"boolean"}
		}
		}');
		

//		"restore_dir":{"type":"string"},
//		"restore_sharedfolder_uuid":{"type":"string"}
		
    #throw new OMVException(OMVErrorMsg::E_MISC_FAILURE,"Path: \"".$params['restore_sharedfolder_uuid']."\" / \"".$params['restore_dir']."\"");
    
    
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

		$xpath_tmp = sprintf("//system/shares/sharedfolder[uuid='%s']",$object['source_sharedfolder_uuid']);$object_tmp = $xmlConfig->get($xpath_tmp);if(is_null($object_tmp)){throw new OMVException(OMVErrorMsg::E_CONFIG_GET_OBJECT_FAILED,$xpath_tmp);}
		$GET_SOURCE_PATH = $object_tmp['reldirpath'];
		$xpath_tmp = sprintf("//system/fstab/mntent[uuid='%s']",$object_tmp['mntentref']);$object_tmp = $xmlConfig->get($xpath_tmp);if(is_null($object_tmp)){throw new OMVException(OMVErrorMsg::E_CONFIG_GET_OBJECT_FAILED,$xpath_tmp);}
		$GET_SOURCE_MNT = $object_tmp['dir'];
		$GET_SOURCE_PATH = $GET_SOURCE_MNT."/".$GET_SOURCE_PATH."/";
		
		$xpath_tmp = sprintf("//system/shares/sharedfolder[uuid='%s']",$object['target_sharedfolder_uuid']);$object_tmp = $xmlConfig->get($xpath_tmp);if(is_null($object_tmp)){throw new OMVException(OMVErrorMsg::E_CONFIG_GET_OBJECT_FAILED,$xpath_tmp);}
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
		$filename = "/var/lib/openmediavault/sbackup.d/manual_restore_".$params['uuid'];
		$scriptfile = fopen($filename, "w");
		fwrite($scriptfile, "#!/bin/sh\n");
    fwrite($scriptfile, "# This configuration file is auto-generated.\n");
    fwrite($scriptfile, "# WARNING: Do not edit this file, your changes will be lost.\n");
    fwrite($scriptfile, ". /usr/share/openmediavault/scripts/helper-functions\n");
    fwrite($scriptfile, "SB_TIMESTART=\$(date +\"%s\")\n");
    fwrite($scriptfile, "cleanup() {\n");
    fwrite($scriptfile, "  omv_kill_children \$\$\n");
    fwrite($scriptfile, "  RSSIZE=\$(cat \"".$OMV_SBACKUP_SESLOGDIR."/".$params['uuid']."_\${SB_TIMESTART}.log\"|awk '/^Total file size: / {print \$4}')\n");
    fwrite($scriptfile, "  RSPERF=\$(cat \"".$OMV_SBACKUP_SESLOGDIR."/".$params['uuid']."_\${SB_TIMESTART}.log\"|awk '/ bytes\/sec\$/ {print \$(NF-1)}')\n");
    fwrite($scriptfile, "  SB_TIMEEND=\$(date +\"%s\")\n");
    fwrite($scriptfile, "  if [ \"\${SB_ECODE}\" = \"\" ]; then\n");
    fwrite($scriptfile, "    SB_ECODE=-1\n");
    fwrite($scriptfile, "  fi\n");
		fwrite($scriptfile, "  cat \"".$OMV_SBACKUP_LOGFILE."\"|sed \"s/^running|\(.*\)|\(.*\)|\${SB_TIMESTART}||||restore|/\${SB_ECODE}|\\1|\\2|\${SB_TIMESTART}|\${SB_TIMEEND}|\${RSSIZE}|\${RSPERF}|restore|/g\" > \"".$OMV_SBACKUP_LOGFILE.".new\"\n");
    fwrite($scriptfile, "  mv \"".$OMV_SBACKUP_LOGFILE.".new\" \"".$OMV_SBACKUP_LOGFILE."\"\n");
    fwrite($scriptfile, "  echo \"\n\nEnd time: \$(date -d @\${SB_TIMEEND})\nStatus: \${SB_ECODE}\" >> \"".$OMV_SBACKUP_SESLOGDIR."/".$params['uuid']."_\${SB_TIMESTART}.log\"\n");
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
    fwrite($scriptfile, "echo \"restore|\$\$|\" > \"".$runfile."\"\n");
    fwrite($scriptfile, "# Create target directory.\n");
    fwrite($scriptfile, "mkdir -p \"".$GET_SOURCE_PATH."\"\n");
    fwrite($scriptfile, "echo \"running|".$object['name']."|".$params['uuid']."|\${SB_TIMESTART}||||restore|\" >> \"".$OMV_SBACKUP_LOGFILE."\"\n");
    fwrite($scriptfile, "echo \"Backup name: ".$object['name']."\nUUID: ".$params['uuid']."\nStart time: \$(date -d @\${SB_TIMESTART})\n\n\" > \"".$OMV_SBACKUP_SESLOGDIR."/".$params['uuid']."_\${SB_TIMESTART}.log\"\n");
    fwrite($scriptfile, "trap cleanup 0 1 2 5 9 15\n");
    fwrite($scriptfile, "rsync --verbose --stats -aEAX");
    if($params['deleteold'])fwrite($scriptfile, " --delete");
    fwrite($scriptfile, " \"".$GET_TARGET_DEST."\" \"".$GET_SOURCE_PATH."\" 2>&1 >> \"".$OMV_SBACKUP_SESLOGDIR."/".$params['uuid']."_\${SB_TIMESTART}.log\"\n");
    fwrite($scriptfile, "SB_ECODE=\$(echo \$?)");
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
  	  	
		$xpath_post = sprintf("//services/sbackup/backuplist/backup[uuid='%s']",$params['uuid']);
		$object_post = $xmlConfig->get($xpath_post);
		if(is_null($object_post)) {throw new OMVException(OMVErrorMsg::E_CONFIG_GET_OBJECT_FAILED,$xpath_post);}
  	  	

		$xpath_tmp = sprintf("//system/shares/sharedfolder[uuid='%s']",$object_post['target_sharedfolder_uuid']);$object_tmp = $xmlConfig->get($xpath_tmp);if(is_null($object_tmp)){throw new OMVException(OMVErrorMsg::E_CONFIG_GET_OBJECT_FAILED,$xpath_tmp);}
		$GET_TARGET_PATH = $object_tmp['reldirpath'];
		$xpath_tmp = sprintf("//system/fstab/mntent[uuid='%s']",$object_tmp['mntentref']);$object_tmp = $xmlConfig->get($xpath_tmp);if(is_null($object_tmp)){throw new OMVException(OMVErrorMsg::E_CONFIG_GET_OBJECT_FAILED,$xpath_tmp);}
		$GET_TARGET_DEST = $object_tmp['dir']."/".$GET_TARGET_PATH."/sbackup_".$params['uuid']."/";
		
		if(!file_exists($GET_TARGET_DEST))throw new OMVException(OMVErrorMsg::E_CONFIG_GET_OBJECT_FAILED,"backup directory not accessible: ".$GET_TARGET_DEST);
  	  	
		if(file_exists("/var/log/sbackup/history_".$params['uuid'])){
			$txt_file = file_get_contents("/var/log/sbackup/history_".$params['uuid']);
			$lines    = explode("\n", $txt_file);
			foreach($lines as $line){
				if(!$line)continue;
				$rows = explode("|", $line);
				if($rows[0] != "0" || $rows[7] != "backup")continue;
				
  			if($object_post['job_type'] == "backup") $job_type = "Backup";
  			if($object_post['job_type'] == "restore")$job_type = "Restore";
  			if($object_post['job_type'] == "purge")  $job_type = "Purge";
  			if($object_post['job_type'] == "copy")   $job_type = "Copy";
  			if($object_post['job_type'] == "verify") $job_type = "Verify";
  			
				if(file_exists($GET_TARGET_DEST."/data_".$rows[3]."/")){
    			$result[] = array(
    				"version" => $rows[3],
    				"version_human" => $job_type.": ".date('r', $rows[3])
    			);
    		}
			}
		}
  	return $result;
  }
  /**
	* getJobList
	*/
  public function getJobList($params, $context) {
  	global $xmlConfig;
  	// Validate the RPC caller context.
  	$this->validateMethodContext($context, array(
  	"role" => OMV_ROLE_ADMINISTRATOR
  	));
		$this->validateMethodParams($params, '{
		"type":"object",
		"properties":{
		"uuid":{"type":"string"},
		"jobtype":{"type":"string"},
		"jobtype_exclude":{"type":"string"},
		"jobtype_empty":{"type":"string"}
		}
		}');
  	
  	// Prepare the result list.
  	$result = array();
  	
		// Get the configuration objects.
		$xpath = "//services/sbackup/backuplist/backup";
		$objects = $xmlConfig->getList($xpath);
		if(is_null($objects)) {
			throw new OMVException(OMVErrorMsg::E_CONFIG_GET_OBJECT_FAILED,
			$xpath);
		}
		// Add additional share informations.
		if($params['jobtype_empty']){
  		$result[] = array(
  			"job_uuid" => "",
  			"job_name" => $params['jobtype_empty']
  		);
		}
		foreach($objects as $objectk => &$objectv) {
			$job_type = "N/A";
			if($params['jobtype'] == "backup"  && $objectv['job_type'] != "backup")continue;
			if($params['jobtype'] == "restore" && $objectv['job_type'] != "restore")continue;
			if($params['jobtype'] == "purge"   && $objectv['job_type'] != "purge")continue;
			if($params['jobtype'] == "copy"    && $objectv['job_type'] != "copy")continue;
			if($params['jobtype'] == "verify"  && $objectv['job_type'] != "verify")continue;
			if($params['jobtype_exclude'] == "me" && $objectv['uuid'] == $params['uuid'])continue;
			if($objectv['job_type'] == "backup") $job_type = "Backup";
			if($objectv['job_type'] == "restore")$job_type = "Restore";
			if($objectv['job_type'] == "purge")  $job_type = "Purge";
			if($objectv['job_type'] == "copy")   $job_type = "Copy";
			if($objectv['job_type'] == "verify") $job_type = "Verify";
			
			$result[] = array(
				"job_uuid" => $objectv['uuid'],
				"job_name" => $job_type.": ".$objectv['name']
			);
		}
  	
  	return $result;
  }

}

// Register the RPC service.
$rpcServiceMgr = &OMVRpcServiceMgr::getInstance(); // Get the "root" instance for the Services
$rpcServiceMgr->registerService(new OMVRpcServiceSBackup()); // Register a new instance of the RPC service described above
?>
