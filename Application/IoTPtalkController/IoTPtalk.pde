import processing.serial.*;

class IoTPtalk {
  IoTPtalk() {
    encoder = new Encoder();
  }
  void set(Serial _serial)
  {
    serial = _serial;
  }
  String getText()
  {
    String str_result = "";
    ArrayList<Byte>text = new ArrayList<Byte>();

    while (serial.available() > 0 ) {      
      text.add((byte)serial.read());
      delay(1);
    }
    
    for ( int i = 0; i  < text.size(); i++ ) {
      if ( text.get(i) > 0  ) {        
        str_result = str_result + char(text.get(i));
      } else {    
        if( i == text.size()-1 ){
        }
        else{
          str_result =  str_result + encoder.getUtfString(text.get(i), text.get(i+1));
        }
        i++;
      }
    }
    
    return str_result;
  }
  int available()
  {
    return serial.available();
  }
  String reset()
  {
    String str_result = "";
    serial.write("CMD,RESET,0");    
    return str_result;
  }

  String getStatus()
  {    
    return command("CMD,GETSTATUS,0");
  }

  String getCaption()
  {
    return getText();
  }
  String command(String _str_command)
  {
    String str_result = "";
    serial.write(_str_command);
    delay(100);
    while (serial.available() > 0 ) {      
      str_result = str_result + (char)serial.read();
      delay(1);
    }
    return str_result;
  }
  String getSSID()
  {
    ssid =  command("CMD,GETSSID,0");
    return ssid;
  }
  String getPassword()
  {
    password = command("CMD,GETPASS,0");
    return password;
  }
  void close()
  {
    serial.clear();
  }
  Serial serial;
  String ssid;
  String password;
  Encoder encoder;
}
