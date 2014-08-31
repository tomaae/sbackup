/**
 * This file is part of OpenMediaVault.
 *
 * @license   http://www.gnu.org/licenses/gpl.html GPL Version 3
 * @author    Volker Theile <volker.theile@openmediavault.org>
 * @copyright Copyright (c) 2009-2014 Volker Theile
 *
 * OpenMediaVault is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 *
 * OpenMediaVault is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with OpenMediaVault. If not, see <http://www.gnu.org/licenses/>.
 */
// require("js/omv/tree/Panel.js")
// require("js/omv/data/Model.js")
// require("js/omv/data/proxy/Rpc.js")
// require("js/omv/data/reader/RpcArray.js")

Ext.define("OMV.tree.RestoreDirBrowser", {
  extend: "OMV.tree.Panel",
  requires: [
   "OMV.data.Model",
   "OMV.data.proxy.Rpc",
   "OMV.data.reader.RpcArray"
  ], 
  
  autoScroll: true,
  rootVisible: false,
 
  initComponent: function() {
   var me = this;
   Ext.apply(me, {
    store: Ext.create("Ext.data.TreeStore", {
     autoLoad: true,
     model: OMV.data.Model.createImplicit({
      fields: [
       { name: "text", type: "string", mapping: 0 },
       { name: "name", type: "string", mapping: 0 }
      ]
     }),
     proxy: {
      type: "rpc",
      reader: "rpcarray",
      appendSortParams: false,
      rpcData: {
       service: "sbackup",
       method: "getRestoreDirBrowser",
       params: {
        uuid: me.uuid,
        backupuuid:this.backupuuid,
        version: this.version
       }
      }
     },
     sorters: [{
      direction: "ASC",
      property: "text"
     }],
     root: Ext.apply({
      expanded: false, // Load children async.
      text: "/",
      name: "/"
     }, me.root || {}),
     listeners: {
      scope: me,
      beforeload: function(store, operation) {
       // Modify the RPC parameters.
       Ext.apply(store.proxy.rpcData.params, {
        path: this.getPathFromNode(operation.node)
       });
      }
     }
    })
   });
   // Delete the 'root' config object, otherwise the ExtJS procedure
   // takes action which might result in unexpected behaviour.
   if(Ext.isDefined(me.root))
    delete me.root;
   me.callParent(arguments);
  },
 
 	setVersion: function(value) {
 		this.store.proxy.rpcData.params.version="sbackup_"+this.store.proxy.rpcData.params.backupuuid+"/data_"+value
 		this.store.reload(); 
 	},
 
  /**
   * Gets the hierarchical path from the root to the given node.
   * @param node The node to process.
   * @return The hierarchical path from the root to the given node,
   *   e.g. '/backup/data/private'.
   */
  getPathFromNode: function(node) {
   var path = [ node.get("name") ];
   var parent = node.parentNode;
   while (parent) {
    path.unshift(parent.get("name"));
    parent = parent.parentNode;
   }
   return path.join("/");
  }
});