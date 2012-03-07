package moudles.chatModule.xmpp.stanza.impl
{
	import moudles.chatModule.xmpp.XMPPConnHander;
	import moudles.chatModule.xmpp.jid.JID;
	import moudles.chatModule.xmpp.stanza.Stanza;

	public class PresenceStanza extends Stanza
	{
		public var from:JID = new JID();
		public var to:JID = new JID();
		public var type:String = 'available';
		public var status:String = '';
		public var priority:String = '0';
		public var category:String = 'available';
		namespace jc = 'jabber:client';
		default xml namespace = 'jabber:client';
		
		
		public function PresenceStanza(connection:XMPPConnHander)
		{
			super(connection);
		}
		
		override public function processXMPP(inxml:XML):void {
			super.processXMPP(inxml);
			default xml namespace = "jabber:client";
			from.fromString(xml.@from);
			to.fromString(xml.@to);
			this.type = xml.@type;
			this.status = xml.status.text();
			this.priority = xml.priority.text();
			if(!this.type) {
				this.type = xml.show.text();
			}
			if(!this.type) {
				this.type = 'available';
			}
		}
				
	}
}