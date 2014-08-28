
Ext.define("OMV.module.admin.service.sbackup.settings", {
	extend: "OMV.workspace.form.Panel",
	
	rpcService: "SBackup",
	rpcGetMethod: "getSettings",
	rpcSetMethod: "setSettings",
	
  getFormItems: function() {
  	return [{
  		xtype: "fieldset",
  		title: _("Log settings"),
  		fieldDefaults: {
  			labelSeparator: ""
  		},
  		items: [{
  			xtype: "numberfield",
  			name: "backuplogretention",
  			fieldLabel: "History retention",
  			minValue: 0,
  			maxValue: 365,
  			allowDecimals: false,
  			allowBlank: true,
  			plugins: [{
					ptype: "fieldinfo",
					text: _("Specifies how many days to store backup history.")
				}]
  		},{
  			xtype: "numberfield",
  			name: "sessionlogretention",
  			fieldLabel: "Log retention",
  			minValue: 0,
  			maxValue: 365,
  			allowDecimals: false,
  			allowBlank: true,
  			plugins: [{
					ptype: "fieldinfo",
					text: _("Specifies how many days to store session logs.")
				}]
  		}]
  	}];
  }
});

// Register the class that is defined above
OMV.WorkspaceManager.registerPanel({
	id: "settings", //Individual id
	path: "/service/sbackup", // Parent folder in the navigation view
	text: _("Settings"), // Text to show on the tab , Shown only if multiple form panels
	position: 90, // Horizontal position of this tab. Use when you have multiple tabs
	className: "OMV.module.admin.service.sbackup.settings" // Same class name as defined above
});