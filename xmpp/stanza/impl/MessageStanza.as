package moudles.chatModule.xmpp.stanza.impl
{
	import com.im.utils.Control;
	
	import moudles.chatModule.xmpp.XMPPConnHander;
	import moudles.chatModule.xmpp.events.XMPPEvent;
	import moudles.chatModule.xmpp.jid.JID;
	import moudles.chatModule.xmpp.stanza.Stanza;

	public class MessageStanza extends Stanza
	{
		public function MessageStanza(connection:XMPPConnHander)
		{
			super(connection);
		}
		
		override public function processXMPP(inxml:XML):void {
			super.processXMPP(inxml);
			_dispatcherHander.dispatchEvent(new XMPPEvent(XMPPEvent.MESSAGE_RECEIVING,inxml));
		}
		
		public function sendMessage(xmlOut:*,to:String,type:String="chat"):void {
			var xml:XML = <message />;
			var fulljid:JID=this.connHander.fulljid;
			xml.@from = fulljid.toString();
			xml.@to = to;
			xml.@type = type;
			var bodyx:XML = new XML();
			bodyx = <body>{xmlOut}</body>;
			xml.appendChild(bodyx);
			this.send(xml.toString());
		}
	}
}