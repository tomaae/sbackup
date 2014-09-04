Ext.define("OMV.module.admin.service.sbackup.backuphistory", {
	extend: "OMV.workspace.grid.Panel",
	requires: [
	"OMV.Rpc",
	"OMV.data.Store",
	"OMV.data.Model",
	"OMV.data.proxy.Rpc",
	"OMV.window.Execute"
	],

	hidePagingToolbar: false,
	hideAddButton: true,
	hideEditButton: true,
	hideDeleteButton: true,
	reloadOnActivate : true,
	autoReload : true,
	reloadInterval : 60000,
	stateful: true,
	stateId: "693bddb2-7765-11e2-8c62-00221568ca71",
	columns: [{
		text: _("Id"),
		sortable: true,
		width: 35,
		dataIndex: "id",
		stateId: "id"
	},{
		text: _("Type"),
		sortable: true,
		width: 90,
		dataIndex: "sessiontype",
		stateId: "sessiontype"
	},{
		text: _("Backup name"),
		sortable: true,
		width: 150,
		dataIndex: "name",
		stateId: "name"
	},{
		text: _("Status"),
		sortable: true,
		width: 150,
		dataIndex: "job_status",
		stateId: "job_status"
	},{
		text: _("Start time"),
		sortable: true,
		width: 200,
		dataIndex: "starttime",
		stateId: "starttime"
	},{
		text: _("End time"),
		sortable: true,
		width: 200,
		dataIndex: "endtime",
		stateId: "endtime"
	},{
		text: _("Size"),
		sortable: true,
		dataIndex: "backupsize",
		stateId: "backupsize"
	},{
		text: _("Performance"),
		sortable: true,
		dataIndex: "backupperf",
		stateId: "backupperf"
	},{
		text: _("Log"),
		sortable: true,
		width: 35,
		dataIndex: "haslog",
		stateId: "haslog"
	}],

	initComponent: function() {
		var me = this;
		Ext.apply(me, {
			store: Ext.create("OMV.data.Store", {
				autoLoad: true,
				model: OMV.data.Model.createImplicit({
					idProperty: "fileid",
					fields: [
					{ name: "fileid", type: "string" },
					{ name: "id", type: "string" },
					{ name: "uuid", type: "string" },
					{ name: "sessiontype", type: "string" },
					{ name: "name", type: "string" },
					{ name: "job_status", type: "string" },
					{ name: "starttime", type: "string" },
					{ name: "endtime", type: "string" },
					{ name: "backupsize", type: "string" },
					{ name: "backupperf", type: "string" },
					{ name: "haslog", type: "string" }
					]
				}),
				proxy: {
					type: "rpc",
					rpcData: {
						service: "sbackup",
						method: "getHistory"
					}
				},
				remoteSort: true,
				sorters: [{
					direction: "DESC",
					property: "id"
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
      		var tbarRunCtrl = me.queryById(me.getId() + "-log");
      		if(records.length > 0 && records[ai].data.haslog == "yes")
      			tbarRunCtrl.enable();
      		else
      			tbarRunCtrl.disable();
      		var tbarRestoreCtrl = me.queryById(me.getId() + "-restore");
      		var tbarPurgeCtrl = me.queryById(me.getId() + "-purge");
      		if(records.length > 0 && (records[ai].data.sessiontype == "Backup")){
      			tbarRestoreCtrl.enable();
      			tbarPurgeCtrl.enable();
      		}else{
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
		// Add 'Log' button to top toolbar
		Ext.Array.insert(items, 2, [{
			id: me.getId() + "-log",
			xtype: "button",
			text: _("Session log"),
			icon: "images/logs.png",
			iconCls: Ext.baseCSSPrefix + "btn-icon-16x16",
			handler: Ext.Function.bind(me.onShowlog, me, [ me ]),
			scope: me,
			disabled: true
		},{
			id: me.getId() + "-restore",
			xtype: "button",
			text: _("Restore version"),
			icon: "images/ftp.png",
			iconCls: Ext.baseCSSPrefix + "btn-icon-16x16",
			handler: Ext.Function.bind(me.onRestoreVersionButton, me, [ me ]),
			scope: me,
			disabled: true
		},{
			id: me.getId() + "-purge",
			xtype: "button",
			text: _("Purge version"),
			icon: "images/delete.png",
			iconCls: Ext.baseCSSPrefix + "btn-icon-16x16",
			handler: Ext.Function.bind(me.onPurgeVersionButton, me, [ me ]),
			scope: me,
			disabled: true
		}]);
		return items;
	},

	onSelectionChange: function(model, records) {
		var me = this;
		me.callParent(arguments);
		// Process additional buttons.
		var tbarRunCtrl = me.queryById(me.getId() + "-log");
		if(records.length > 0 && records[0].data.haslog == "yes")
			tbarRunCtrl.enable();
		else
			tbarRunCtrl.disable();
		var tbarRestoreCtrl = me.queryById(me.getId() + "-restore");
		var tbarPurgeCtrl = me.queryById(me.getId() + "-purge");
		if(records.length > 0 && (records[0].data.sessiontype == "Backup")){
			tbarRestoreCtrl.enable();
			tbarPurgeCtrl.enable();
		}else{
			tbarRestoreCtrl.disable();
			tbarPurgeCtrl.disable();
		}
	},

	onShowlog: function() {
		var me = this;
		var record = me.getSelected();
		Ext.create("OMV.window.Execute", {
			title: _("Backup session log"),
			hideStopButton: true,
			rpcService: "sbackup",
			rpcMethod: "showLog",
			rpcParams: {
				fileid: record.get("fileid")
			},
			listeners: {
				scope: me,
				exception: function(wnd, error) {
					OMV.MessageBox.error(null, error);
				}
			}
		}).show();
	},
	
	onRestoreVersionButton: function() {
		var me = this;
		var record = me.getSelected();
		//placeholder
	},
	
	onPurgeVersionButton: function() {
		var me = this;
		var record = me.getSelected();
		//placeholder
	}
});

// Register the class that is defined above
OMV.WorkspaceManager.registerPanel({
	id: "backuphistory", //Individual id
	path: "/service/sbackup", // Parent folder in the navigation view
	text: _("Backup history"), // Text to show on the tab , Shown only if multiple form panels
	position: 20, // Horizontal position of this tab. Use when you have multiple tabs
	className: "OMV.module.admin.service.sbackup.backuphistory" // Same class name as defined above
});