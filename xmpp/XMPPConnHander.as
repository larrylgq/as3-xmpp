
package moudles.chatModule.xmpp
{
	import com.im.utils.Control;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.Socket;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import moudles.chatModule.xmpp.events.XMPPEvent;
	import moudles.chatModule.xmpp.jid.JID;
	import moudles.chatModule.xmpp.stanza.Stanza;
	import moudles.chatModule.xmpp.stanza.impl.IqStanza;
	import moudles.chatModule.xmpp.stanza.impl.MessageStanza;
	import moudles.chatModule.xmpp.stanza.impl.PresenceStanza;
	import moudles.chatModule.xmpp.stanza.impl.StreamStanza;
	
	public class XMPPConnHander
	{
		private var _dispatcherHander:Control=Control.getInstance();
		/**
		 * 开关控制
		 */
		//socket
		public var socket:Object = null;
		//服务器	
		public var host:String;
		public var server:String;
		public var port:uint;
		public var fulljid:JID= new JID();
		//根节点
		public var rootStanzas:Dictionary = new Dictionary();
		
		public var stream_start:String = "<stream>";//流起始
		public var stream_end:String = "</stream>";//流结束
		
		//心跳间隔时间
		public var ping_timer:Timer = new Timer(90000);
		
		//发送信息通道
		public var sendMessageStanza:MessageStanza;
		
		/**
		 * 单例一个XMPPSocket
		 */
		private static var __instance:XMPPConnHander=null;
		public static function getInstance():XMPPConnHander
		{
			if(__instance == null)
			{
				__instance=new XMPPConnHander();
			}  
			return __instance;
		}
		
		public function XMPPConnHander()
		{
		}
		
		/**
		 * 配置
		 */
		public function doConnConfig(jid:String,psw:String,server:String="gt-guiqiangl-01", port:int=5222,resource:String="LTalke"):void{
			this.fulljid.fromString(jid);
			this.host = fulljid.host;
			fulljid.resource=resource;
			
			this.server=server;
			this.port = port;
			
			stream_start = "<stream:stream to=\"" + host + "\" xmlns:stream='http://etherx.jabber.org/streams' xmlns='jabber:client' version='1.0'>";
			stream_end = "</stream:stream>";
			
			//接收
			rootStanzas['{jabber:client}iq'] = new IqStanza(this);
			rootStanzas['{jabber:client}message'] =new MessageStanza(this);
			rootStanzas['{jabber:client}presence'] =new PresenceStanza(this);
			rootStanzas['streamstanza'] =new StreamStanza(this,psw);
			//发送
			sendMessageStanza=new MessageStanza(this);
			
			ping_timer.addEventListener(TimerEvent.TIMER, pingServer);//心跳处理事件
		}
		
		/**
		 * 打开连接
		 */
		public function startSocket():void{
			this.socket = new Socket();
			configureListeners();
		}
		
		/**
		 * 结束连接
		 */
		public function closeSocket():void{
			if(socket&&socket.connected){
				unConfigureListeners();
				socket.close();
				socket=null;
			}
			ping_timer.stop();  
		}
		
		
		
		/**
		 * 添加监听
		 */
		public function configureListeners():void
		{ 
			socket.addEventListener(Event.CLOSE, closeHandler);
			socket.addEventListener(Event.CONNECT, connectHandler);
			socket.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			socket.addEventListener(ProgressEvent.SOCKET_DATA, socketDataHandler);
		}
		
		/**
		 * 移出监听
		 */
		public function unConfigureListeners():void
		{
			socket.removeEventListener(Event.CLOSE, closeHandler);
			socket.removeEventListener(Event.CONNECT, connectHandler);
			socket.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			socket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			socket.removeEventListener(ProgressEvent.SOCKET_DATA, socketDataHandler);
		}
		
		
		/**
		 * <设置			<<<<<<
		 * >连接处理		>>>>>>
		 */
		
		/**
		 * 连接
		 */
		public function connect():void {
			socket.connect(server, port);
		}
		
		/**
		 * 连接中断
		 */
		private function closeHandler(event:Event):void {
			closeSocket();
			_dispatcherHander.dispatchEvent(new XMPPEvent(XMPPEvent.CONNECT_FAILED,"连接中断"));
		}
		
		/**
		 * 连接成功
		 */
		private function connectHandler(event:Event):void {
			send(stream_start);
		}
		
		/**
		 * 连接通道异常
		 */
		private function ioErrorHandler(event:IOErrorEvent):void {
			_dispatcherHander.dispatchEvent(new XMPPEvent(XMPPEvent.CONNECT_FAILED,"连接通道异常"));
		}
		
		/**
		 * 安全沙箱
		 */
		private function securityErrorHandler(event:SecurityErrorEvent):void {
			_dispatcherHander.dispatchEvent(new XMPPEvent(XMPPEvent.CONNECT_FAILED,"权限验证失败"));
		}
		
		
		/**
		 * <监听方法	    <<<<<<
		 * >处理方法		>>>>>>
		 */
		
		
		/**
		 * 发送心跳包至服务器
		 */
		private function pingServer(e:TimerEvent):void {
			var id:String = newId();
			var pingxml:XML = <iq to={host} id={id} type='get'><ping xmlns='urn:xmpp:ping'/></iq>;
			send(pingxml.toXMLString());
		}
		
		/**
		 * 自增请求包序号
		 */
		//发送请求包的序号
		private var stanzaId:uint = 0;
		public function newId():String {
			stanzaId += 1;
			return String(stanzaId);
		}
		
		/**
		 * 处理方法		<<<<<<
		 * 数据处理		>>>>>>
		 */
		
		/**
		 * 发送数据
		 */
		public function send(data:String):void {
			trace("         OUT: " + data);
			try {
				socket.writeUTFBytes(data);
				socket.flush();
			} catch (error:Error) {
				
			}
		}
		  
		/**
		 * 处理接收的数据
		 */
		private var getTag:RegExp = /(?<=(\<))[a-zA-Z:]+/i;
		public var stream_started:Boolean=false;
		private var stream_string:String;
		private var stream_tag:String;
		public var buffer:String;
		public function socketDataHandler(event:ProgressEvent):void {
			var incoming:String = socket.readUTFBytes(socket.bytesAvailable);
			trace("IN : " + incoming);
			var tag:Array =[];
			buffer += incoming;
			if(!stream_started && buffer) {
				if(buffer.search("\\?>") != -1) {
					buffer = buffer.substring(buffer.search("\\?>") + 2)
				}
				tag = getTag.exec(buffer);
				if(tag && tag[0].search('stream') > -1)
				{
					stream_tag = tag[0];
					stream_string = "<" + buffer.substring(buffer.search(tag[0]), buffer.search('>')) + ">";
					buffer = buffer.substring(buffer.search('>') + 1);
					stream_started = true;
				}
			}
			var gotfulltag:Boolean = true;
			while(gotfulltag) {
				tag = getTag.exec(buffer);
				if(tag) {
					var completeXML:RegExp = new RegExp("(\<" + tag[0] + "([^(\>)]+?)(/\>))|((\<" + tag[0] + "(.+?)\</" + tag[0] + "\>)+?)", "s"); // pull out tag with this TODO:account for CDATA
					var xmlstr:Object = completeXML.exec(buffer);
					if(xmlstr) {
						buffer = buffer.substring(buffer.search(xmlstr[0]) + xmlstr[0].length);
						incomingHandler(stream_string + xmlstr[0] + "</" + stream_tag + ">");
					} else {
						gotfulltag = false;
					}
				} else {
					gotfulltag = false;
				}
			}
		}
		
		/**
		 * 将数据转成xml进一步处理
		 */
		private var xmlDoc:XML;
		private function incomingHandler(xmlstring:String):void {
			var currentStanza:Stanza;
			xmlDoc = XML(xmlstring);
			var xml:XML = xmlDoc.children()[0];
			var match:String = "{" + xml.namespace() + "}" + xml.localName();
			if(rootStanzas.hasOwnProperty(match)) {
				currentStanza = rootStanzas[match];
			} else {
				currentStanza = rootStanzas['streamstanza'];
			}
			currentStanza.processXMPP(xml);
		}
		
	}
	
	
}