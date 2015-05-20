# nginx-1.8.0
Nginx-1.8.0 (unofficial)  with http_push_module

#The compiling version with components:

* [nginx-1.8.0] (http://nginx.org/download/nginx-1.8.0.tar.gz)
* [nginx_http_push_module-0.712] (https://pushmodule.slact.net/)
* [pcre-8.37] (http://sourceforge.net/projects/pcre/files/)
* [zlib-1.2.8] (http://zlib.net/zlib-1.2.8.tar.gz)

Additional libraries (for compiler process):
--------------------------------------------

* `libgd2-xpm-dev` 
* `checkinstall`
* `libssl-dev` 
* `make` 
* `openssl` 
* `automake`

Nginx install on path:
----------------------
 
 `- nginx_path: /etc/nginx`
 `- logs: /var/log/nginx`
 `- www: /var/www/html`
 `- libs: /user/local/nginx/libs`
 
Run script:
-----------
	```
	/etc/init.d/nginx {start|stop|restart}
	```
or	
	```
	service nginx {start|stop|restart}
	```
	
#Install 

  ```	
  sudo ./install.sh
  ```	
  
Publish/Subscribe channel (example - add in virtual host configure):
--------------------------------------------------------------------

	```
	location /channelPublish {
		# Name of variable with channel name
		# in this example is "channel" link as bottom:
		# http://example.com/channelPublish?channel=s42378fwe
		set $push_channel_id $arg_channel;
		push_publisher;
		# Disable message storage (message has remove after seen)
		push_store_messages off;
	}


	location /channelSubscribe {
		push_subscriber;
		push_subscriber_concurrency broadcast;
		
		# Channel id
		set $push_channel_id $arg_channel;
		
		# clear all access_log directives for the current level
		access_log off;
		add_header Cache-Control no-cache;
	    	# set the Expires header to 31 December 2037 23:59:59 GMT, and the Cache-Control max-age to 10 years
        	expires 1s;
		
		# Response type
		default_type text/plain;
	}
	```
	
Send info in publish channel with command (example in php):
-----------------------------------------------------------

		```
		$c = curl_init( $address . '/channelPublish?channel=' . $channel );
		curl_setopt($c, CURLOPT_RETURNTRANSFER, false);
		curl_setopt($c, CURLOPT_POST, true);
		curl_setopt($c, CURLOPT_POSTFIELDS, !is_string($data) ? json_encode($data) : $data );
		$r = curl_exec($c);
		```
		
Listen subscribe channel from client side (example in javascript with [jQuery](https://jquery.com/) ):
------------------------------------------------------------------------------------------------------
	
	```
	$.get('/channelSubscribe?channel=<channelId>',function(response){
		//Received data sended in public channel
		console.log(response);
	},'json');
	```

See [contributors] (contributors.md)
 


