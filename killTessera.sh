ps aux|grep tessera |awk {'print$2'}
sudo kill -9 $(ps aux|grep geth |awk {'print$2'})
