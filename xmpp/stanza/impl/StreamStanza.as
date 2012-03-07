package moudles.chatModule.xmpp.stanza.impl
{
	import com.hurlant.crypto.tls.TLSConfig;
	import com.hurlant.crypto.tls.TLSEngine;
	import com.hurlant.crypto.tls.TLSSocket;
	import moudles.chatModule.xmpp.XMPPConnHander;
	import moudles.chatModule.xmpp.events.XMPPEvent;
	import moudles.chatModule.xmpp.jid.JID;
	import moudles.chatModule.xmpp.stanza.Stanza;
	
	import flash.net.Socket;
	import flash.utils.Dictionary;
	
	import mx.utils.Base64Encoder;
	
	public class StreamStanza extends Stanza
	{
		//用于tls
		private var tlsConfig:Dictionary=new Dictionary();
		//保存流状态
		public var streamState:Dictionary = new Dictionary();
		//是否使用tls
		public var use_tls:Boolean = true;
		private var password:String;
		
		//bind的命名空间
		namespace xmpp_bind = "urn:ietf:params:xml:ns:xmpp-bind";
		
		
		//tlssocket
		public var tlssocket:TLSSocket;
		public function StreamStanza(connection:XMPPConnHander,psw:String)
		{
			super(connection);
			this.password=psw;
			initState();
		}

		/**
		 * 初始化状态
		 */
		public function initState():void {
			streamState['authed'] = false;
			streamState['bound'] = false;
			streamState['encrypted'] = false;
			
			tlsConfig['_ignoreInvalidCert']=true;
			tlsConfig['_ignoreCommonName']=true;
			tlsConfig['_ignoreSelfSigned']=true;
		}
		//接收发送>>
		/**
		 * 接收xml事件
		 */
		override public function processXMPP(inxml:XML):void {
			var nodeName:String = inxml.localName().toString().toLowerCase();
			switch( nodeName )
			{
				case "stream:error":
					break;
				case "features":
					streamFeaturesHandler(inxml);
					break;
				case "failure":
					_dispatcherHander.dispatchEvent(new XMPPEvent(XMPPEvent.CONNECT_FAILED,"验证失败"));
					break;
				case "success":
					authSuccessHandler(inxml);
					break;
				case "proceed":
					tlsProceedHandler(inxml);
					break;
				default:
					break;
			}
		}
		
		//事件处理>>
		/**
		 * 握手成功事件
		 */
		private function authSuccessHandler(xml:XML):void {
			streamState['authed'] = true;
			send(this.connHander.stream_start);
			this.connHander.stream_started= false;
		}
		
		/**
		 * 打开tls
		 */
		private function tlsProceedHandler(xml:XML):void {
			try {
				var clientConfig:TLSConfig=new TLSConfig(TLSEngine.CLIENT);
				clientConfig.ignoreCommonNameMismatch = this.tlsConfig['_ignoreCommonName'];
				//连接gtalk时配置以下2项为false会发生错误
				clientConfig.trustAllCertificates = this.tlsConfig['_ignoreInvalidCert'];
				clientConfig.trustSelfSignedCertificates = tlsConfig['_ignoreSelfSigned'];
				tlssocket = new TLSSocket();
				//tlssocket.addEventListener(TLSEvent.READY, onTLSReady);
				this.connHander.unConfigureListeners();
				tlssocket.startTLS(Socket(this.connHander.socket), this.connHander.host, clientConfig);
				this.connHander.socket = tlssocket;
				this.connHander.configureListeners();
				streamState['encrypted'] = true;    
				
				connHander.stream_started= false;  
				send(this.connHander.stream_start);
			} catch (error:Error) {
				
			}
		}

		/**  
		 * 处理流特征
		 */
		private function streamFeaturesHandler(xmlobj:XML):void {
			var fulljid:JID=this.connHander.fulljid;
			if(use_tls && !(streamState['authed']) && !(streamState['encrypted']) &&nodeCompare(xmlobj,<starttls/>)){
				send("<starttls xmlns='urn:ietf:params:xml:ns:xmpp-tls' />");
			} else if (!(streamState['authed'])) {
				if(nodeCompareCompletely(xmlobj,<mechanism>PLAIN</mechanism>) && fulljid && password){
					var encodedauth:Base64Encoder = new Base64Encoder();
					encodedauth.encode("\x00" + fulljid.user + "\x00" + password);
					send("<auth xmlns='urn:ietf:params:xml:ns:xmpp-sasl' mechanism='PLAIN'>" + encodedauth.toString() + "</auth>" );
				}else if(nodeCompareCompletely(xmlobj,<mechanism>ANONYMOUS</mechanism>)&&(!fulljid || !password)){
					send("<auth xmlns='urn:ietf:params:xml:ns:xmpp-sasl' mechanism='ANONYMOUS' />" );
				}
			} else if (!streamState['authed']) {
				trace("没有支持的加密方式");
				this.connHander.closeSocket();
			} else if (streamState['authed']) {
				if (!streamState['bound'] &&nodeCompare(xmlobj,<bind/>)) {
					var iqID:String =connHander.newId();
					var iq:XML = <iq type='set' id={iqID}><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></iq>;
					if(fulljid) {
						var resx:XML = <resource>{fulljid.resource}</resource>;
						iq.xmpp_bind::bind.appendChild(resx);
					}
					send(iq.toXMLString());
				}
			}
		}
	}
}