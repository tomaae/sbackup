/**
* Backup modal
*/
Ext.define("OMV.module.admin.service.sbackup.backup", {
	extend: "OMV.workspace.window.Form",
	requires: [
	"OMV.data.Store",
	"OMV.data.Model",
	"OMV.data.proxy.Rpc"
	],
	uses: [
	"OMV.workspace.window.plugin.ConfigObject"
	],

	rpcService: "SBackup",
	rpcGetMethod: "get",
	rpcSetMethod: "set",
	plugins: [{
		ptype: "configobject"
	}],
	width: 570,
	height: 400,

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
			fieldLabel: _("Backup name"),
			allowBlank: false
		},{
			xtype: "sharedfoldercombo",
			name: "sharedfoldersource",
			fieldLabel: _("Source"),
			plugins: [{
				ptype: "fieldinfo",
				text: _("Shared folder to backup.")
			}]
		},{
			xtype: "sharedfoldercombo",
			name: "sharedfoldertarget",
			fieldLabel: _("Destination"),
			plugins: [{
				ptype: "fieldinfo",
				text: _("Backup destination.")
			}]
		},{
  			xtype: "numberfield",
  			name: "retention",
  			fieldLabel: "Backup retention",
  			minValue: 0,
  			maxValue: 365,
  			value: 1,
  			allowDecimals: false,
  			allowBlank: true,
  			plugins: [{
					ptype: "fieldinfo",
					text: _("Specifies how many days backup should be stored.")
				}]
  	},{
			xtype: "combo",
			name: "wday",
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
			name: "hour",
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
			name: "minute",
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
			name: "savelog",
			fieldLabel: _("Save backup log"),
			checked: true
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
        fieldLabel: _("Version"),
        emptyText: _("Select version ..."),
        store: Ext.create("OMV.data.Store", {
          autoLoad: true,
          model: OMV.data.Model.createImplicit({
            idProperty: "devicefile",
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
            }
          },
          sorters: [{
            direction: "DESC",
            property: "version"
          }]
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
			uuid: me.sharedfoldertarget,
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
    		name: "savelog",
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
        				savelog: options.savelog,
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
		text: _("Backup name"),
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
		dataIndex: "running",
		stateId: "running"
	},{
		text: _("Last completed"),
		sortable: true,
		width: 200,
		dataIndex: "lastcompleted",
		stateId: "lastcompleted"
	},{
		text: _("Backup source"),
		sortable: true,
		dataIndex: "sourcefoldername",
		stateId: "sourcefoldername"
	},{
		text: _("Backup target"),
		sortable: true,
		dataIndex: "targetfoldername",
		stateId: "targetfoldername"
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
					{ name: "sharedfoldertarget", type: "string" },
					{ name: "enable", type: "boolean" },
					{ name: "name", type: "string" },
					{ name: "running", type: "string" },
					{ name: "lastcompleted", type: "string" },
					{ name: "targetfoldername", type: "string" },
					{ name: "sourcefoldername", type: "string" },
					{ name: "schedule", type: "string" },
					{ name: "retention", type: "string" },
					{ name: "versions", type: "string" }
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
      		var tbarRunCtrl = this.queryById(me.getId() + "-run");
					var tbarRestoreCtrl = this.queryById(me.getId() + "-restore");
      		if(records.length > 0 && (records[ai].data.running == "Running" || records[ai].data.running == "Restoring")){
						tbarRunCtrl.disable();
						tbarRestoreCtrl.disable();
					}else{
						tbarRunCtrl.enable();
						tbarRestoreCtrl.enable();
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
		}]);
		return items;
	},

	onSelectionChange: function(model, records) {
		var me = this;
		me.callParent(arguments);
		// Process additional buttons.
		var tbarRunCtrl = me.queryById(me.getId() + "-run");
		if(records.length <= 0)
		tbarRunCtrl.disable();
		else if(records.length == 1)
			tbarRunCtrl.enable();
			else
				tbarRunCtrl.disable();
				var tbarRestoreCtrl = me.queryById(me.getId() + "-restore");
				if(records.length > 0 && records[0].data.lastcompleted != "N/A")
				tbarRestoreCtrl.enable();
				else
					tbarRestoreCtrl.disable();
		if(records.length > 0 && (records[0].data.running == "Running" || records[0].data.running == "Restoring")){
			tbarRunCtrl.disable();
			tbarRestoreCtrl.disable();
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
			sharedfoldertarget: record.get("sharedfoldertarget"),
			sourcefoldername: record.get("sourcefoldername"),
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

  onRunButton: function() {
  	var me = this;
  	var record = me.getSelected();
  	OMV.MessageBox.show({
  		title: _("Confirmation"),
  		msg: _("Do you really want to start backup?"),
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
