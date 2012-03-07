
package moudles.chatModule.xmpp.jid
{
	public class JID
	{
		public var user:String = '';
		public var host:String = '';
		public var resource:String = '';
		
		public function JID(jid:String=null)
		{
			if(jid) fromString(jid);
		}
	
		public function fromString(jid:String):void {
			if(!jid) return;
			var tmp:Array;
			if(jid.search('@') > 0) {
				tmp = jid.split('@');
				user = tmp[0];
				host = tmp[1];
			} else {
				host = jid;
			}
			if(host.search('/') > 0) {
				tmp = host.split('/');
				resource = tmp[1];
				if(!resource) resource = ''
				host = tmp[0];
			}
		}
		
		public function getResource():String {
			return resource;
		}
		
		public function isSet():Boolean {
			if(this.user != '' || this.host != '') {
				return true;
			}
			return false;
		}
		
		public function getBareJID():String {
			var out:String;
			if(user) {
				out = user + '@' + host;
			} else {
				out = host; 
			}
			return out;
		}
		
		public function toString():String {
			var out:String = getBareJID();
			if(resource) out += '/' + resource;
			return out;
		}
	}
}