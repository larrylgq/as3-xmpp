package moudles.chatModule.xmpp.stanza
{
	import moudles.chatModule.xmpp.XMPPConnHander;
	import moudles.chatModule.xmpp.jid.JID;
	import com.im.utils.Control;
	
	public class Stanza
	{
		public var _dispatcherHander:Control=Control.getInstance();
		public var connHander:XMPPConnHander;
		public var xml:XML;
		
		public function Stanza(connection:XMPPConnHander)
		{
			this.connHander = connection;
		}
		
		/*接收*/
		public function processXMPP(inxml:XML):void {
			this.xml = inxml;
		}
		
		/*发送*/
		public function sendXMPP(inxml:XML):void {
			
		}
		
		public function send(data:String):void {
			this.connHander.send(data);;
		}
		
		public function getXML():XML {
			return this.xml;
		}
		
		
		/*根据localname判断xml匹配*/
		public function nodeCompare(searchNode:XML, findNode:XML):XML {
			for each(var searchSub:XML in searchNode.children()) {
				if(searchSub.localName()==findNode.localName()){
					return searchSub;
				}else{
					var xml:XML=nodeCompare(searchSub,findNode);
					if(xml){
						return xml;
					}
				}
			}
			return null;
		}
		
		/**
		 * 判断xml完全匹配
		 */
		public function nodeCompareCompletely(searchNode:XML, findNode:XML):XML {
			for each(var searchSub:XML in searchNode.children()) {
				if(searchSub.toString()==findNode.toString()){
					return searchSub;
				}else{
					var xml:XML=nodeCompare(searchSub,findNode);
					if(xml){
						return xml;
					}
				}
			}
			return null;
		}
	}
}