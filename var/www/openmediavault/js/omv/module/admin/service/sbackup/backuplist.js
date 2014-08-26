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

        /**
         * The class constructor.
         * @fn constructor
         * @param uuid The UUID of the database/configuration object. Required.
         */

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
                }];
        }
});

//Ext.define("OMV.module.admin.service.sbackup.backuplist", { // Define a new class
//	extend: "OMV.workspace.form.Panel", // What is the base type of this class
//	uses: [
//          "OMV.module.admin.service.sbackup.backup"
//        ],
//  hidePagingToolbar: false,
//	rpcService: "SBackup", // Remote Procedure Call
//	rpcGetMethod: "getbackuplist", // Remote Procedure Call
//	rpcSetMethod: "setbackuplist", // Remote Procedure Call
//	
//  onAddButton: function() {
//        var me = this;
//        var record = me.getSelected();
//        Ext.create("OMV.module.admin.service.sbackup.backup", {
//                title: _("Add backup job"),
//                uuid: OMV.UUID_UNDEFINED,
//                listeners: {
//                        scope: me,
//                        submit: function() {
//                                this.doReload();
//                        }
//                }
//        }).show();
//  },
//  
//	getFormItems: function() { // Generic function for this class that initializes the GUI
//		return [{
//			xtype: "fieldset", // Type of the item
//			title: _("Backup list"), // Text that is shown on the top edge of the fieldset
//			fieldDefaults: {
//				labelSeparator: ""
//			},
//			items: [{ // These items are inside the fieldset item defined above
//				xtype: "checkbox", // Type of the item
//				name: "enable", // Individual name of the item
//				fieldLabel: _("Enable"), // Text that is shown next to the checkbox. Keep this under 15 characters
//				checked: false // Default value if no settings have been applied yet, Try to change this to true
//			},
//			{
//				xtype: "numberfield", // Type of the item
//				name: "numberfield1", // Individual name of the item
//				fieldLabel: "Number", // Text that is shown next to the number field. Keep this under 15 characters
//				minValue: 0, // Self explanatory
//				allowDecimals: false, // Self explanatory
//				allowBlank: true // Self explanatory
//			}]
//		}];
//	}
//});

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
        stateId: "693bddb2-7765-11e2-8c62-00221568ca88",
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
                text: _("Name"),
                sortable: true,
                dataIndex: "name",
                stateId: "name"
        },{
                text: _("Status"),
                sortable: true,
                dataIndex: "running",
                stateId: "running"
        },{
                text: _("Shared folder"),
                sortable: true,
                dataIndex: "sourcefoldername",//sharedfoldername
                stateId: "sourcefoldername"
        },{
                text: _("Backup target"),
                sortable: true,
                dataIndex: "targetfoldername",//fsuuid
                stateId: "targetfoldername"
        },{
                text: _("Schedule"),
                sortable: true,
                dataIndex: "schedule",
                stateId: "schedule"
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
                                                { name: "enable", type: "boolean" },
                                                { name: "name", type: "string" },
                                                { name: "running", type: "string" },
                                                { name: "targetfoldername", type: "string" },
                                                { name: "sourcefoldername", type: "string" },
                                                { name: "schedule", type: "string" }
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
                                        property: "sourcefoldername"
                                }]
                        })
                });
                me.callParent(arguments);
        },

//        getTopToolbarItems: function() {
//                var me = this;
//                var items = me.callParent(arguments);
//                // Add 'Run' button to top toolbar
//                Ext.Array.insert(items, 2, [{
//                        id: me.getId() + "-run",
//                        xtype: "button",
//                        text: _("Run"),
//                        icon: "images/play.png",
//                        iconCls: Ext.baseCSSPrefix + "btn-icon-16x16",
//                        handler: Ext.Function.bind(me.onRunButton, me, [ me ]),
//                        scope: me,
//                        disabled: true
//                }]);
//                return items;
//        },

//        onSelectionChange: function(model, records) {
//                var me = this;
//                me.callParent(arguments);
//                // Process additional buttons.
//                var tbarRunCtrl = me.queryById(me.getId() + "-run");
//                if(records.length <= 0)
//                        tbarRunCtrl.disable();
//                else if(records.length == 1)
//                        tbarRunCtrl.enable();
//                else
//                        tbarRunCtrl.disable();
//        },

        onAddButton: function() {
                var me = this;
                var record = me.getSelected();
                Ext.create("OMV.module.admin.service.sbackup.backup", {
                        title: _("Add backup job"),
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
                        title: _("Edit backup job"),
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
        }//,
//
//        onRunButton: function() {
//                var me = this;
//                var record = me.getSelected();
//                Ext.create("OMV.window.Execute", {
//                        title: _("Execute backup job"),
//                        rpcService: "sbackup",
//                        rpcMethod: "execute",
//                        rpcParams: {
//                                uuid: record.get("uuid")
//                        },
//                        listeners: {
//                                scope: me,
//                                exception: function(wnd, error) {
//                                        OMV.MessageBox.error(null, error);
//                                }
//                        }
//                }).show();
//        }
});

// Register the class that is defined above
OMV.WorkspaceManager.registerPanel({
	id: "backuplist", //Individual id
	path: "/service/sbackup", // Parent folder in the navigation view
	text: _("Backup list"), // Text to show on the tab , Shown only if multiple form panels
	position: 10, // Horizontal position of this tab. Use when you have multiple tabs
	className: "OMV.module.admin.service.sbackup.backuplist" // Same class name as defined above
});
