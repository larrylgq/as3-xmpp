package moudles.chatModule.xmpp.events
{
	import flash.events.Event;
	
	public class XMPPEvent extends Event
	{
		public static const CONNECT_FAILED:String = "stream-connect-failed";
		public static const SESSION:String = "xmpp-session";
		
		
		public static const ROSTER_ITEM:String = "xmpp-roster-item";
		public static const ROSTER_ERROR:String = "xmpp-roster-error";
		
		public static const MESSAGE_RECEIVING:String = "message-receiving";
		
		public var stanza:Object;
		public function XMPPEvent(type:String, stanza:Object, bubbles:Boolean=false, cancelable:Boolean=false)
		{ 
			this.stanza = stanza;
			super(type, bubbles, cancelable);
		}
	}
}