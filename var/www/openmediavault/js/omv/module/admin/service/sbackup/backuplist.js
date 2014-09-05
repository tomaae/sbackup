
/**
* Backup modal
*/
Ext.define("OMV.module.admin.service.sbackup.backup", {
	extend: "OMV.workspace.window.Form",
	requires: [
	"OMV.data.Store",
	"OMV.data.Model",
	"OMV.data.proxy.Rpc",
	"OMV.form.plugin.LinkedFields"
	],
	uses: [
	"OMV.workspace.window.plugin.ConfigObject"
	],

	rpcService: "SBackup",
	rpcGetMethod: "get",
	rpcSetMethod: "set",
	plugins: [{
		ptype: "configobject"
	},{
    ptype: "linkedfields",
    correlations: [{
        conditions: [
          {name: "job_type", value: "backup"}
        ],
        name: [
          "backup_type",
          "source_sharedfolder_uuid",
          "target_sharedfolder_uuid",
          "protect_days_job",
          "post_purge"
        ],
        properties: ["show"]
    },{
        conditions: [
          {name: "job_type", value: "backup"}
        ],
        name: [
          "source_sharedfolder_uuid",
          "target_sharedfolder_uuid",
        ],
        properties: ["!allowBlank"]
    },{
        conditions: [
          {name: "job_type", value: "purge"}
        ],
        name: [
          "purge_job_uuid"
        ],
        properties: ["show"]
    },{
        conditions: [
          {name: "job_type", value: "purge"}
        ],
        name: [
          "purge_job_uuid"
        ],
        properties: ["!allowBlank"]
    },{
        conditions: [
          {name: "job_type", value: "verify"}
        ],
        name: [
          "verify_job_uuid"
        ],
        properties: ["show"]
    },{
        conditions: [
          {name: "job_type", value: "verify"}
        ],
        name: [
          "verify_job_uuid"
        ],
        properties: ["!allowBlank"]
    }]
  }],
	width: 570,
	//height: 400,

	getFormItems: function() {
		var me = this;
		return [{
			xtype: "checkbox",
			name: "enable",
			fieldLabel: _("Enable"),
			checked: true
		},{
			xtype: "textfield",
			name: "name",
			fieldLabel: _("Job name"),
			allowBlank: false
		},{
			xtype: "combo",
			name: "job_type",
			fieldLabel: _("Job type"),
			queryMode: "local",
			store: Ext.create("Ext.data.ArrayStore", {
				fields: [ "value", "text" ],
				data: [
				[ "backup", _("Backup") ],
				//[ "copy",   _("Copy") ],
				[ "purge",  _("Purge") ],
				//[ "verify", _("Verify") ]
				]
			}),
			displayField: "text",
			valueField: "value",
			allowBlank: false,
			editable: false,
			triggerAction: "all",
			value: "backup",
			plugins: [{
				ptype: "fieldinfo",
				text: _("Job type.")
			}]
		},{
			xtype: "combo",
			name: "backup_type",
			fieldLabel: _("Backup type"),
			queryMode: "local",
			store: Ext.create("Ext.data.ArrayStore", {
				fields: [ "value", "text" ],
				data: [
				[ "sharedfolder", _("Shared folder") ],
				//[ "filesystem",   _("Filesystem") ],
				//[ "idb",          _("Internal Database") ],
				//[ "mysql",        _("MySQL") ]
				]
			}),
			displayField: "text",
			valueField: "value",
			hidden: true,
			allowBlank: false,
			editable: false,
			triggerAction: "all",
			value: "sharedfolder",
			plugins: [{
				ptype: "fieldinfo",
				text: _("Type of backup source.")
			}]
		},{
			xtype: "sharedfoldercombo",
			name: "source_sharedfolder_uuid",
			fieldLabel: _("Source"),
			hidden: true,
			allowBlank: true,//switched
			plugins: [{
				ptype: "fieldinfo",
				text: _("Shared folder to backup.")
			}]
		},{
			xtype: "sharedfoldercombo",
			name: "target_sharedfolder_uuid",
			fieldLabel: _("Target"),
			hidden: true,
			allowBlank: true,//switched
			plugins: [{
				ptype: "fieldinfo",
				text: _("Backup destination.")
			}]
		},{
  			xtype: "numberfield",
  			name: "protect_days_job",
  			fieldLabel: "Retention",
  			minValue: 0,
  			maxValue: 365,
  			value: 1,
  			allowDecimals: false,
  			allowBlank: true,
  			hidden: true,
  			plugins: [{
					ptype: "fieldinfo",
					text: _("Specifies how many days backup/copy should be stored.")
				}]
  	},{
			xtype: "combo",
			name: "purge_job_uuid",
			fieldLabel: _("Backup"),
			queryMode: "local",
			emptyText: _("Select backup ..."),
			store: Ext.create("Ext.data.ArrayStore", {
				autoLoad: true,
				model: OMV.data.Model.createImplicit({
					idProperty: "postjob",
					fields: [
						{ name: "job_name", type: "string" },
						{ name: "job_uuid", type: "string" }
					]
				}),
				proxy: {
					type: "rpc",
					appendSortParams: false,
					rpcData: {
						service: "sbackup",
						method: "getJobList",
						params: {
							uuid: me.uuid,
							jobtype: "backup",
							jobtype_exclude: "",
							jobtype_empty: ""
						}
					}
				},
				sorters: [{
					direction: "ASC",
					property: "job_name"
				}]
			}),
			displayField: "job_name",
			valueField: "job_uuid",
			editable: false,
			allowBlank: true,//switched
			triggerAction: "all",
			value: "",
			plugins: [{
				ptype: "fieldinfo",
				text: _("Backup job to purge.")
			}]
		},{
			xtype: "combo",
			name: "verify_job_uuid",
			fieldLabel: _("Backup"),
			queryMode: "local",
			emptyText: _("Select backup ..."),
			store: Ext.create("Ext.data.ArrayStore", {
				autoLoad: true,
				model: OMV.data.Model.createImplicit({
					idProperty: "postjob",
					fields: [
						{ name: "job_name", type: "string" },
						{ name: "job_uuid", type: "string" }
					]
				}),
				proxy: {
					type: "rpc",
					appendSortParams: false,
					rpcData: {
						service: "sbackup",
						method: "getJobList",
						params: {
							uuid: me.uuid,
							jobtype: "backup",
							jobtype_exclude: "",
							jobtype_empty: ""
						}
					}
				},
				sorters: [{
					direction: "ASC",
					property: "job_name"
				}]
			}),
			displayField: "job_name",
			valueField: "job_uuid",
			editable: false,
			allowBlank: true,//switched
			triggerAction: "all",
			value: "",
			plugins: [{
				ptype: "fieldinfo",
				text: _("Backup job to verify.")
			}]
		},{
			xtype: "combo",
			name: "schedule_wday",
			fieldLabel: _("Day"),
			queryMode: "local",
			store: Ext.create("Ext.data.ArrayStore", {
				fields: [ "value", "text" ],
				data: [
				[ "7", _("Daily") ],
				[ "1", _("Monday") ],
				[ "2", _("Tuesday") ],
				[ "3", _("Wednesday") ],
				[ "4", _("Thursday") ],
				[ "5", _("Friday") ],
				[ "6", _("Saturday") ],
				[ "0", _("Sunday") ]
				]
			}),
			displayField: "text",
			valueField: "value",
			allowBlank: false,
			editable: false,
			triggerAction: "all",
			value: "7"
		},{
			xtype: "combo",
			name: "schedule_hour",
			fieldLabel: _("Hour"),
			queryMode: "local",
			store: Ext.create("Ext.data.ArrayStore", {
				fields: [ "value", "text" ],
				data: [
				[ "00", _("00") ],
				[ "01", _("01") ],
				[ "02", _("02") ],
				[ "03", _("03") ],
				[ "04", _("04") ],
				[ "05", _("05") ],
				[ "06", _("06") ],
				[ "07", _("07") ],
				[ "08", _("08") ],
				[ "09", _("09") ],
				[ "10", _("10") ],
				[ "11", _("11") ],
				[ "12", _("12") ],
				[ "13", _("13") ],
				[ "14", _("14") ],
				[ "15", _("15") ],
				[ "16", _("16") ],
				[ "17", _("17") ],
				[ "18", _("18") ],
				[ "19", _("19") ],
				[ "20", _("20") ],
				[ "21", _("21") ],
				[ "22", _("22") ],
				[ "23", _("23") ]
				]
			}),
			displayField: "text",
			valueField: "value",
			allowBlank: false,
			editable: false,
			triggerAction: "all",
			value: "00"
		},{
			xtype: "combo",
			name: "schedule_minute",
			fieldLabel: _("Minute"),
			queryMode: "local",
			store: Ext.create("Ext.data.ArrayStore", {
				fields: [ "value", "text" ],
				data: [
				[ "00", _("00") ],
				[ "15", _("15") ],
				[ "30", _("30") ],
				[ "45", _("45") ]
				]
			}),
			displayField: "text",
			valueField: "value",
			allowBlank: false,
			editable: false,
			triggerAction: "all",
			value: "00"
		},{
			xtype: "checkbox",
			name: "sessionlog_save",
			fieldLabel: _("Save log"),
			checked: true,
			plugins: [{
				ptype: "fieldinfo",
				text: _("Save detailed session log.")
			}]
		},{
			xtype: "checkbox",
			name: "post_purge",
			fieldLabel: _("Purge"),
			checked: true,
			hidden: true,
			plugins: [{
				ptype: "fieldinfo",
				text: _("Start purge after successful backup. Do NOT uncheck unless necessery.")
			}]
		},{
			xtype: "combo",
			name: "post_job",
			fieldLabel: _("Post job"),
			queryMode: "local",
			emptyText: _("No job selected"),
			store: Ext.create("Ext.data.ArrayStore", {
				autoLoad: true,
				model: OMV.data.Model.createImplicit({
					idProperty: "postjob",
					fields: [
						{ name: "job_name", type: "string" },
						{ name: "job_uuid", type: "string" }
					]
				}),
				proxy: {
					type: "rpc",
					appendSortParams: false,
					rpcData: {
						service: "sbackup",
						method: "getJobList",
						params: {
							uuid: me.uuid,
							jobtype: "all",
							jobtype_exclude: "me",
							jobtype_empty: "No job selected"
						}
					}
				},
				sorters: [{
					direction: "ASC",
					property: "job_name"
				}]
			}),
			displayField: "job_name",
			valueField: "job_uuid",
			editable: false,
			triggerAction: "all",
			value: "",
			plugins: [{
				ptype: "fieldinfo",
				text: _("Start another job after successful completion.")
			}]
		}];
	}
});

/**
* Restore modal
*/
Ext.define("OMV.module.admin.service.sbackup.restore", {
	extend: "OMV.window.Window",
	uses: [
	"OMV.Rpc",
	"OMV.grid.Privileges",
	"OMV.tree.Folder",
	"OMV.util.Format",
	"OMV.data.Model",
  "OMV.data.Store",
  "OMV.tree.RestoreDirBrowser"
	],
  
	readOnly: false,

	title: _("Restore from backup"),
	width: 700,
	height: 520,
	layout: "border",
	modal: true,
	buttonAlign: "center",
	border: false,

	initComponent: function() {
		var me = this;
		
    me.vp = Ext.create("OMV.form.Panel", {
    	region: "north",
    	split: true,
    	collapsible: false,
    	bodyPadding: "5 5 0",
    	border: true,
    	items: [{
        xtype: "combo",
        name: "version",
        id: "versioncombo",
        fieldLabel: _("Version"),
        emptyText: _("Select version ..."),
        store: Ext.create("OMV.data.Store", {
          autoLoad: true,
          model: OMV.data.Model.createImplicit({
            idProperty: "backupversion",
            fields: [
              { name: "version", type: "string" },
              { name: "version_human", type: "string" }
            ]
          }),
          proxy: {
            type: "rpc",
            appendSortParams: false,
            rpcData: {
      				service: "sbackup",
      				method: "getVersions",
      				params: {
      					uuid: me.uuid
      				}
            },
          },
          sorters: [{
            direction: "DESC",
            property: "version"
          }],
//          listeners: {
//            scope: me,
//            load: function(combo, records){
//                  var sel = Ext.getCmp('versioncombo');
//
//                  sel.select(combo.data.items[0].data.version)
//                  var record = sel.getStore().findRecord('version', combo.data.items[0].data.version);
//                  sel.fireEvent('select', sel, [record]);
//            }
//          }
        }),
        displayField: "version_human",
        valueField: "version",
        allowBlank: false,
        editable: false,
        triggerAction: "all",
        
        listeners: {
          scope: me,
          select: function(combo, records) {
            var record = records[0];
            this.tp.setVersion(record.get("version"));
          }
        }
			}]
    });
		
		me.tp = Ext.create("OMV.tree.RestoreDirBrowser", {
			title: _("Browse directories"),
			autoLoad: false,
			split: false,
			width: 700,
			height: 400,
			collapsible: false,
			uuid: me.target_sharedfolder_uuid,
			backupuuid: me.uuid,
			version: "",
			rootVisible: true      
 		});

    me.fp = Ext.create("OMV.form.Panel", {
    	title: _("Options"),
    	region: "south",
    	split: true,
    	collapsible: false,
    	bodyPadding: "5 5 0",
    	border: true,
    	items: [{
    		xtype: "checkbox",
    		name: "deleteold",
    		fieldLabel: _("Delete source"),
    		checked: false,
    		boxLabel: _("Delete all data from source")
    	},{
    		xtype: "checkbox",
    		name: "sessionlog_save",
    		fieldLabel: _("Log"),
    		checked: true,
    		boxLabel: _("Save restore log")
    	}]
    });
		
		Ext.apply(me, {
			buttons: [{
				text: _("Start restore"),
				handler: me.onApplyButton,
				scope: me,
				disabled: me.readOnly
			},{
				text: _("Close"),
				handler: me.close,
				scope: me
			}],
			items: [ me.vp, me.tp, me.fp ]
		});
		me.callParent(arguments);
	},
	
  onApplyButton: function() {
  	var me = this;
  	var node = me.tp.getSelectionModel().getSelection()[0];
  	var options = me.fp.getValues();
  	var version = me.vp.getValues();
    if(version.version != parseInt(version.version) || typeof node === 'undefined'){
     	if(version.version != parseInt(version.version)){
     		OMV.MessageBox.info(null, _("Please select version first."));
     	}else	if(typeof node === 'undefined')OMV.MessageBox.info(null, _("Please select directory first."));
    }else{
    	var dir = "",dirnode = node
    	while(dirnode.data.root == false){
    		dir = dirnode.data.name+"/"+dir
    		dirnode = dirnode.parentNode
    	}
  
    	OMV.MessageBox.show({
    		title: _("Confirmation"),
    		msg: _("Do you really want to start restore?"),
    		buttons: Ext.Msg.YESNO,
    		fn: function(answer) {
    			if(answer === "no")
    			return;
        	// Execute RPC
        	OMV.Rpc.request({
        		scope: me,
        		callback: function(id, success, response) {
        			this.close();
        		},
        		relayErrors: false,
        		rpcData: {
        			service: "sbackup",
        			method: "runRestore",
        			params: {
        				uuid: me.uuid,
        				dir: dir,
        				deleteold: options.deleteold,
        				sessionlog_save: options.sessionlog_save,
        				version: version.version
        			}
        		}
        	});
    		},
    		scope: me,
    		icon: Ext.Msg.QUESTION
    	});
  	}
	}
});

/**
* Purge modal
*/
Ext.define("OMV.module.admin.service.sbackup.purge", {
	extend: "OMV.window.Window",
	uses: [
	"OMV.Rpc",
	"OMV.util.Format",
	"OMV.data.Model",
  "OMV.data.Store"
	],
  
	readOnly: false,

	title: _("Purge versions from backup"),
	width: 700,
	height: 159,
	layout: "border",
	modal: true,
	buttonAlign: "center",
	border: false,

	initComponent: function() {
		var me = this;
		
    me.fp = Ext.create("OMV.form.Panel", {
    	title: _("Options"),
    	region: "south",
    	split: false,
    	collapsible: false,
    	bodyPadding: "5 5 0",
    	border: true,
    	items: [{
  			xtype: "numberfield",
  			name: "retention",
  			fieldLabel: "Retention",
  			minValue: 0,
  			maxValue: 365,
  			value:me.retention,
  			allowDecimals: false,
  			allowBlank: true,
  			plugins: [{
					ptype: "fieldinfo",
					text: _("How many days to keep?.")
				}]
  		},{
    		xtype: "checkbox",
    		name: "sessionlog_save",
    		fieldLabel: _("Log"),
    		checked: true,
    		boxLabel: _("Save restore log")
    	}]
    });
		
		Ext.apply(me, {
			buttons: [{
				text: _("Start purge"),
				handler: me.onApplyButton,
				scope: me,
				disabled: me.readOnly
			},{
				text: _("Close"),
				handler: me.close,
				scope: me
			}],
			items: [ me.fp ]
		});
		me.callParent(arguments);
	},
	
  onApplyButton: function() {
  	var me = this;
  	var options = me.fp.getValues();

  	OMV.MessageBox.show({
  		title: _("Confirmation"),
  		msg: _("Do you really want to start purge?"),
  		buttons: Ext.Msg.YESNO,
  		fn: function(answer) {
  			if(answer === "no")
  			return;
      	// Execute RPC
      	OMV.Rpc.request({
      		scope: me,
      		callback: function(id, success, response) {
      			this.close();
      		},
      		relayErrors: false,
      		rpcData: {
      			service: "sbackup",
      			method: "runPurge",
      			params: {
      				uuid: me.uuid,
      				sessionlog_save: options.sessionlog_save,
      				retention: options.retention
      			}
      		}
      	});
  		},
  		scope: me,
  		icon: Ext.Msg.QUESTION
  	});
	}
});

/**
* backuplist
*/
Ext.define("OMV.module.admin.service.sbackup.backuplist", {
	extend: "OMV.workspace.grid.Panel",
	requires: [
	"OMV.Rpc",
	"OMV.data.Store",
	"OMV.data.Model",
	"OMV.data.proxy.Rpc",
	"OMV.window.Execute"
	],
	uses: [
	"OMV.module.admin.service.sbackup.backup"
	],

	hidePagingToolbar: false,
	stateful: true,
	reloadOnActivate : true,
	autoReload : true,
	reloadInterval : 10000,
	stateId: "693bddb2-7765-11e2-8c62-00221568ca70",
	columns: [{
		xtype: "booleaniconcolumn",
		text: _("Enabled"),
		sortable: true,
		dataIndex: "enable",
		stateId: "enable",
		align: "center",
		width: 80,
		resizable: false,
		trueIcon: "switch_on.png",
		falseIcon: "switch_off.png"
	},{
		text: _("Job type"),
		sortable: true,
		width: 70,
		dataIndex: "job_type",
		stateId: "job_type"
	},{
		text: _("Job name"),
		sortable: true,
		width: 150,
		dataIndex: "name",
		stateId: "name"
	},{
		text: _("Schedule"),
		sortable: true,
		width: 120,
		dataIndex: "schedule",
		stateId: "schedule"
	},{
		text: _("Status"),
		sortable: true,
		dataIndex: "job_status",
		stateId: "job_status",
	  renderer: function(value) {
    	switch(value) {
    		case "Running":
    		case "Restoring":
    		case "Purging":
    		case "Migrating":
    		case "Copying":	
    			value = "<img border='0' src='images/wait.gif' height='14' width='14'> <span style='top:-3px;position:relative;'>" + value + "</span>";
    			break;  
    		case "Completed":	
    			value = "<img border='0' src='images/led_green.png' height='14' width='14' /> <span style='top:-3px;position:relative;'>" + value + "</span>";
    			break;  
    		case "N/A":	
    		value = "<img border='0' src='images/led_gray.png' height='14' width='14'> <span style='top:-3px;position:relative;'>" + value + "</span>";
    		  break;	
    		default:
    		value = "<img border='0' src='images/led_red.png' height='14' width='14'> <span style='top:-3px;position:relative;'>" + value + "</span>";
    		  break;
    	}
    	return value;
	  }
	},{
		text: _("Last completed"),
		sortable: true,
		width: 200,
		dataIndex: "lastcompleted",
		stateId: "lastcompleted"
	},{
		text: _("Source"),
		sortable: true,
		dataIndex: "source_name",
		stateId: "source_name",
		renderer: function(value) {
    	switch(value.substr(0, 3)) {
    		case "S: ":	
    			value = "<img border='0' src='images/share.png' height='14' width='14' title='Shared folder'> <span style='top:-3px;position:relative;'>" + value.replace(/^S: /, "") + "</span>";
    			break;  
    		case "B: ":	
    			value = "<img border='0' src='images/hdd.png' height='14' width='14' title='Backup'> <span style='top:-3px;position:relative;'>" + value.replace(/^B: /, "") + "</span>";
    			break;  
    	}
    	return value;
	  }
	},{
		text: _("Target"),
		sortable: true,
		dataIndex: "target_name",
		stateId: "target_name",
		renderer: function(value) {
    	switch(value.substr(0, 3)) {
    		case "S: ":	
    			value = "<img border='0' src='images/share.png' height='14' width='14' title='Shared folder'> <span style='top:-3px;position:relative;'>" + value.replace(/^S: /, "") + "</span>";
    			break;  
    		case "B: ":	
    			value = "<img border='0' src='images/hdd.png' height='14' width='14' title='Backup'> <span style='top:-3px;position:relative;'>" + value.replace(/^B: /, "") + "</span>";
    			break;  
    	}
    	return value;
	  }
	},{
		text: _("Retention"),
		sortable: true,
		width: 80,
		dataIndex: "retention",
		stateId: "retention"
	},{
		text: _("Versions"),
		sortable: true,
		width: 65,
		dataIndex: "versions",
		stateId: "versions"
	},{
		text: _("Size"),
		sortable: true,
		width: 65,
		dataIndex: "size",
		stateId: "size"
	}],

	initComponent: function() {
		var me = this;
		Ext.apply(me, {
			store: Ext.create("OMV.data.Store", {
				autoLoad: true,
				model: OMV.data.Model.createImplicit({
					idProperty: "uuid",
					fields: [
					{ name: "uuid", type: "string" },
					{ name: "retention", type: "string" },
					{ name: "target_sharedfolder_uuid", type: "string" },
					{ name: "enable", type: "boolean" },
					{ name: "job_type", type: "string" },
					{ name: "name", type: "string" },
					{ name: "job_status", type: "string" },
					{ name: "lastcompleted", type: "string" },
					{ name: "target_name", type: "string" },
					{ name: "source_name", type: "string" },
					{ name: "schedule", type: "string" },
					{ name: "protect_days_job", type: "string" },
					{ name: "versions", type: "string" },
					{ name: "size", type: "string" }
					]
				}),
				proxy: {
					type: "rpc",
					rpcData: {
						service: "sbackup",
						method: "getList"
					}
				},
				remoteSort: true,
				sorters: [{
					direction: "ASC",
					property: "name"
				}]
			})
		});
		this.store.on("load", function(store, records, options) {
			var sm = this.getSelectionModel();
      var records_bl = sm.getSelection();
      var ai = -1;
      if(records_bl.length > 0){
      	for (i = 0; i < records.length; i++) { 
      		if(records[i].data.uuid == records_bl[0].data.uuid){
      			ai = i;
      			break;
      		}
      	}
      	if(ai >= 0){
      		var tbarRunCtrl = me.queryById(me.getId() + "-run");
      		if(records.length > 0)
      		  tbarRunCtrl.enable();
      		else tbarRunCtrl.disable();
      		var tbarRestoreCtrl = me.queryById(me.getId() + "-restore");
      		if(records.length > 0 && records[ai].data.lastcompleted != "N/A")
      			tbarRestoreCtrl.enable();
      		else tbarRestoreCtrl.disable();
      		var tbarPurgeCtrl = me.queryById(me.getId() + "-purge");
      		if(records.length > 0 && records[ai].data.versions > 0)
      			tbarPurgeCtrl.enable();
      		else tbarPurgeCtrl.disable();
      		if(records.length > 0 && (records[ai].data.job_status == "Running" || records[ai].data.job_status == "Restoring" || records[ai].data.job_status == "Purging" || records[ai].data.job_status == "Migrating" || records[ai].data.job_status == "Copying")){
      			tbarRunCtrl.disable();
      			tbarRestoreCtrl.disable();
      			tbarPurgeCtrl.disable();
      		}
      		if(records.length > 0 && records[ai].data.job_type != "Backup" ){
      			tbarRestoreCtrl.disable();
      			tbarPurgeCtrl.disable();
      		}
      	}
      }
    }, this);
		me.callParent(arguments);
	},
	
	getTopToolbarItems: function() {
		var me = this;
		var items = me.callParent(arguments);
		// Add buttons to top toolbar
		Ext.Array.insert(items, 2, [{
			id: me.getId() + "-run",
			xtype: "button",
			text: _("Run"),
			icon: "images/play.png",
			iconCls: Ext.baseCSSPrefix + "btn-icon-16x16",
			handler: Ext.Function.bind(me.onRunButton, me, [ me ]),
			scope: me,
			disabled: true
		},{
			id: me.getId() + "-restore",
			xtype: "button",
			text: _("Restore"),
			icon: "images/ftp.png",
			iconCls: Ext.baseCSSPrefix + "btn-icon-16x16",
			handler: Ext.Function.bind(me.onRestoreButton, me, [ me ]),
			scope: me,
			disabled: true
		},{
			id: me.getId() + "-purge",
			xtype: "button",
			text: _("Purge"),
			icon: "images/rsync.png",
			iconCls: Ext.baseCSSPrefix + "btn-icon-16x16",
			handler: Ext.Function.bind(me.onPurgeButton, me, [ me ]),
			scope: me,
			disabled: true
		}]);
		return items;
	},

	onSelectionChange: function(model, records) {
		var me = this;
		me.callParent(arguments);
		// Process additional buttons.
		var tbarRunCtrl = me.queryById(me.getId() + "-run");
		if(records.length > 0)
		  tbarRunCtrl.enable();
		else 	tbarRunCtrl.disable();
		var tbarRestoreCtrl = me.queryById(me.getId() + "-restore");
		if(records.length > 0 && records[0].data.lastcompleted != "N/A")
			tbarRestoreCtrl.enable();
		else tbarRestoreCtrl.disable();
		var tbarPurgeCtrl = me.queryById(me.getId() + "-purge");
		if(records.length > 0 && records[0].data.versions > 0)
			tbarPurgeCtrl.enable();
		else tbarPurgeCtrl.disable();
		if(records.length > 0 && (records[0].data.job_status == "Running" || records[0].data.job_status == "Restoring" || records[0].data.job_status == "Purging" || records[0].data.job_status == "Migrating" || records[0].data.job_status == "Copying")){
			tbarRunCtrl.disable();
			tbarRestoreCtrl.disable();
			tbarPurgeCtrl.disable();
		}
		if(records.length > 0 && records[0].data.job_type != "Backup" ){
			tbarRestoreCtrl.disable();
			tbarPurgeCtrl.disable();
		}
	},

	onAddButton: function() {
		var me = this;
		var record = me.getSelected();
		Ext.create("OMV.module.admin.service.sbackup.backup", {
			title: _("Add backup"),
			uuid: OMV.UUID_UNDEFINED,
			listeners: {
				scope: me,
				submit: function() {
					this.doReload();
				}
			}
		}).show();
	},

	onEditButton: function() {
		var me = this;
		var record = me.getSelected();
		Ext.create("OMV.module.admin.service.sbackup.backup", {
			title: _("Edit backup"),
			uuid: record.get("uuid"),
			listeners: {
				scope: me,
				submit: function() {
					this.doReload();
				}
			}
		}).show();
	},

	doDeletion: function(record) {
		var me = this;
		OMV.Rpc.request({
			scope: me,
			callback: me.onDeletion,
			rpcData: {
				service: "sbackup",
				method: "delete",
				params: {
					uuid: record.get("uuid")
				}
			}
		});
	},

	onRestoreButton: function() {
		var me = this;
		var record = me.getSelected();
		Ext.create("OMV.module.admin.service.sbackup.restore", {
			title: _("Restore from backup"),
			uuid: record.get("uuid"),
			target_sharedfolder_uuid: record.get("target_sharedfolder_uuid"),
			source_name: record.get("source_name"),
			listeners: {
				scope: me,
				close: function() {
  				//var now = new Date().getTime();
  				//while(new Date().getTime() < now + 1500){ /* do nothing */ }
					this.doReload();
				}
			}
		}).show();
	},
	
	onPurgeButton: function() {
		var me = this;
		var record = me.getSelected();
		Ext.create("OMV.module.admin.service.sbackup.purge", {
			title: _("Purge versions from backup"),
			uuid: record.get("uuid"),
			target_sharedfolder_uuid: record.get("target_sharedfolder_uuid"),
			retention:record.get("protect_days_job"),
			source_name: record.get("source_name"),
			listeners: {
				scope: me,
				close: function() {
					this.doReload();
				}
			}
		}).show();
	},

  onRunButton: function() {
  	var me = this;
  	var record = me.getSelected();
  	OMV.MessageBox.show({
  		title: _("Confirmation"),
  		msg: _("Do you really want to start this job?"),
  		buttons: Ext.Msg.YESNO,
  		fn: function(answer) {
  			if(answer === "no")
  			return;
  			// Execute RPC
  			OMV.Rpc.request({
  				scope: me,
  				callback: function(id, success, response) {
  					//var now = new Date().getTime();
  					//while(new Date().getTime() < now + 1500){ /* do nothing */ }
  					this.doReload();
  				},
  				relayErrors: false,
  				rpcData: {
  					service: "sbackup",
  					method: "runBackup",
  					params: {
  						uuid: record.get("uuid")
  					}
  				}
  			});
  		},
  		scope: me,
  		icon: Ext.Msg.QUESTION
  	});
  }
});

// Register the class that is defined above
OMV.WorkspaceManager.registerPanel({
	id: "backuplist", //Individual id
	path: "/service/sbackup", // Parent folder in the navigation view
	text: _("Backup list"), // Text to show on the tab , Shown only if multiple form panels
	position: 10, // Horizontal position of this tab. Use when you have multiple tabs
	className: "OMV.module.admin.service.sbackup.backuplist" // Same class name as defined above
});
