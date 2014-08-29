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
			xtype: "combo",
			name: "btype",
			fieldLabel: _("Backup scheme"),
			queryMode: "local",
			store: Ext.create("Ext.data.ArrayStore", {
				fields: [ "value", "text" ],
				data: [
				[ "rsync", _("Single version") ]
				]
			}),
			displayField: "text",
			valueField: "value",
			allowBlank: false,
			editable: false,
			triggerAction: "all",
			value: "rsync"
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
	"OMV.form.CompositeField"
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
		me.tp = Ext.create("OMV.tree.Folder", {
			title: _("Directory"),
			split: false,
			width: 700,
			height: 400,
			collapsible: false,
			uuid: me.sharedfoldertarget,
			type: "sharedfolder",
			rootVisible: true,
			root: {
				text: me.sourcefoldername,
				name: "sbackup_"+me.uuid
			}
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
			items: [ me.tp, me.fp ]
		});
		me.callParent(arguments);
	},
	
  onApplyButton: function() {
  	var me = this;
  	var node = me.tp.getSelectionModel().getSelection()[0];
  	var options = me.fp.getValues();
  
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
      				savelog: options.savelog
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
		text: _("Backup scheme"),
		sortable: true,
		width: 100,
		dataIndex: "btype",
		stateId: "btype"
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
					{ name: "btype", type: "string" }
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

//	doReload: function() {
//		var me = this;
//		if(me.mode === "remote") {
//			me.store.reload();
//		}
//		var sm = me.getSelectionModel();
//		var records = sm.getSelection(); 
//		if(records.length > 0)alert(records[0].data.name+" "+records[0].data.running)
//	}, 
	
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
