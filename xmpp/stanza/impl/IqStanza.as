package moudles.chatModule.xmpp.stanza.impl
{
	import moudles.chatModule.xmpp.XMPPConnHander;
	import moudles.chatModule.xmpp.events.XMPPEvent;
	import moudles.chatModule.xmpp.jid.JID;
	import moudles.chatModule.xmpp.stanza.Stanza;
	
	import flash.utils.Dictionary;
	
	import mx.utils.ObjectProxy;

	public class IqStanza extends Stanza
	{
		//bind的命名空间
		namespace xmpp_bind = "urn:ietf:params:xml:ns:xmpp-bind";
		namespace rosterns = "jabber:iq:roster";
		
		private var queryStanzas:Dictionary=new Dictionary();
		public function IqStanza(connection:XMPPConnHander)
		{
			super(connection);
			queryStanzas['jabber:iq:roster'] = rosterHander;
		}
		
		override public function processXMPP(inxml:XML):void {
			if(inxml.@type != 'error') {
				if(nodeCompare(inxml,<bind/>)){
					bindResponseHandler(inxml);
				}else if(nodeCompare(inxml,<session/>)){
					sessionResponseHandler(inxml);
				}else{
					var query:XML=nodeCompare(inxml,<query/>);
					if(query){
						if(queryStanzas.hasOwnProperty(query.namespace())){
							queryStanzas['jabber:iq:roster'].call(this,inxml);
						}
					}
				}
			}else{  
				_dispatcherHander.dispatchEvent(new XMPPEvent(XMPPEvent.ROSTER_ERROR,inxml));
			}
		}
		
		/**
		 * 处理好友列表
		 */
		private function rosterHander(inxml:XML):void{
			var groups:Dictionary=new Dictionary();
			for each(var item:XML in inxml.rosterns::query.rosterns::item) {
				var groupValue:String=item.rosterns::group;
				if(!groups.hasOwnProperty(groupValue)){
					var group:Dictionary=new Dictionary();
					group['items']=[];
					if(!groupValue||groupValue==""){
						groupValue="默认";
					}
					group['name']=groupValue;
					groups[groupValue]=group;
				}
				
				var itemObject:ObjectProxy=new ObjectProxy();
				itemObject.jid=item.@jid;
				itemObject.name=item.@name;
				itemObject.ask=item.@ask;
				itemObject.subscription=item.@subscription;
				groups[groupValue]['items'].push(itemObject);
			}
			_dispatcherHander.dispatchEvent(new XMPPEvent(XMPPEvent.ROSTER_ITEM,groups));
		}
		
		/**
		 * 处理资源绑定
		 */
		private function bindResponseHandler(xmlObj:XML):void {
			_dispatcherHander.dispatchEvent(new XMPPEvent(XMPPEvent.SESSION,"会话开启"));
			this.connHander.ping_timer.stop();
			this.connHander.ping_timer.start();
			connHander.fulljid = new JID(xmlObj.xmpp_bind::bind.xmpp_bind::jid.text());
			var iqID:String =connHander.newId();
			var sessionrequest:XML = <iq type='set' id={iqID}><session xmlns='urn:ietf:params:xml:ns:xmpp-session' /></iq>;
			send(sessionrequest);
			getRoster();
			sendPresence();
		}
		
		/**
		 * 打开会话
		 */
		private function sessionResponseHandler(xml:XML):void {	
			this.connHander.ping_timer.stop();
			this.connHander.ping_timer.start();
		}
		
		/**
		 * 发送状态
		 */
		public function sendPresence(status:String=null,show:String=null,priority:String=null,tojid:String=null):void {
			var presence:XML=<presence/>;
			this.send(presence.toXMLString());
		}
		
		/**
		 * 获取列表
		 */
		public function getRoster():void {
			var iqID:String =connHander.newId();
			var jid:String=connHander.fulljid.toString();
			var iq:XML =<iq from={jid} type='get' id={iqID}>
				<query xmlns='jabber:iq:roster'/>
			</iq>;
			this.send(iq.toXMLString());
		}
	}
}