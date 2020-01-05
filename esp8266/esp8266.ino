#include <Adafruit_NeoPixel.h>

/*
  UDPSendReceive.pde:
  This sketch receives UDP message strings, prints them to the serial port
  and sends an "acknowledge" string back to the sender

  A Processing sketch is included at the end of file that can be used to send
  and received messages for testing with a computer.

  created 21 Aug 2010
  by Michael Margolis

  This code is in the public domain.

  adapted from Ethernet library examples
*/


#include <ESP8266WiFi.h>
#include <WiFiUdp.h>
#include <EEPROM.h>

#ifndef STASSID
#define STASSID "shishimobile"
#define STAPSK  "laaemnkb"
#endif

int length_of_ssid;
int length_of_pass;

String str_ssid = "IoTPtalk";
String str_pass = "3748925055132";
unsigned int localPort = 6711;      // local port to listen on

// buffers for receiving and sending data
char packetBuffer[UDP_TX_PACKET_MAX_SIZE + 1]; //buffer to hold incoming packet,
char  ReplyBuffer[] = "acknowledged\r\n";       // a string to send back

#define PIN            4

// How many NeoPixels are attached to the Arduino?
#define NUMPIXELS      1

// When we setup the NeoPixel library, we tell it how many pixels, and which pin to use to send signals.
// Note that for older NeoPixel strips you might need to change the third parameter--see the strandtest
// example for more information on possible values.
Adafruit_NeoPixel pixels = Adafruit_NeoPixel(NUMPIXELS, PIN, NEO_GRB + NEO_KHZ800);


WiFiUDP Udp;


// just one call ,then it updates str_ssid and str_pass
void readEEPROM()
{
  str_ssid = "";
  str_pass = "";
  length_of_ssid = EEPROM.read(0);
  length_of_pass = EEPROM.read(length_of_ssid + 1);
  for ( int i = 1; i < length_of_ssid + 1; i++ ) {
    str_ssid = str_ssid + (char)EEPROM.read(i);
  }
  //str_ssid = str_ssid + '\0';
  for ( int i = length_of_ssid + 1 + 1; i < length_of_ssid + 1 + length_of_pass + 1; i++ ) {
    str_pass = str_pass + (char)EEPROM.read(i);
  }
  //str_pass = str_pass + '\0';
}


void networkStart()
{
  WiFi.mode(WIFI_STA);
  WiFi.begin(str_ssid, str_pass);
  int count = 0;
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print('.');
    pixels.setPixelColor(0, pixels.Color(255, 0, 0));
    pixels.show();
    delay(250);
    pixels.setPixelColor(0, pixels.Color(0, 0, 0));
    pixels.show();
    delay(250);
    count++;
    if ( count > 50 ) {
      Serial.println("Could not connect the AP");
      pixels.setPixelColor(0, pixels.Color(255, 0, 0));
      pixels.show();
      return;
    }
  }
  Serial.println("Connected!");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());
  Serial.print("UDP server on port ");
  Serial.println(localPort);
  Udp.begin(localPort);
  pixels.setPixelColor(0, pixels.Color(0, 255, 0));
  pixels.show();
}
void setup() {
  Serial.begin(74880);
  Serial.println("Welcome to IoTPTalk version.0.1");

  EEPROM.begin(512);
  readEEPROM();


  Serial.println(str_ssid);
  Serial.println(str_pass);
  pixels.begin();
  pixels.setBrightness(100);
  pixels.setPixelColor(0, pixels.Color(255, 0 , 0));

  pixels.show(); // This sends the updated pixel color to the hardware.

  //networkStart();
}


int split(String data, const char delimiter, String *dst) {
  int index = 0;
  int arraySize = (sizeof(data) / sizeof((data)[0]));
  int datalength = data.length();
  for (int i = 0; i < datalength; i++) {
    char tmp = data.charAt(i);
    if ( tmp == delimiter ) {
      index++;
      if ( index > (arraySize - 1)) return -1;
    }
    else dst[index] += tmp;
  }
  return (index + 1);
}



void loop() {

  // Command specification
  /*
     Format: "CMD",command_string,value_string
     Example(set SSID):CMD,SETSSID,ip_address
  */

  String commands[3];
  char char_command[64];
  int data_size = 0;
  while ( Serial.available() > 0 ) {
    char_command[data_size] = Serial.read();
    data_size++;
    delay(1);
  }
  char_command[data_size] = '\0';
  if ( data_size > 0 ) {
    //Serial.printf("%s\n", char_command);
    String str_command = char_command;
    int index = split(str_command, ',', commands);
    if ( commands[0].compareTo("CMD") == 0 ) {
      if ( commands[1].compareTo("GETSSID") == 0 ) {
        Serial.println(str_ssid);
      }
      else if ( commands[1].compareTo("GETPASS") == 0 ) {
        Serial.println(str_pass);
      }
      else if ( commands[1].equals("SETSSID") ) {
        str_ssid = commands[2];
        length_of_ssid = str_ssid.length();
        Serial.printf("length_of_ssid = %d\n", length_of_ssid);

        EEPROM.write(0, length_of_ssid);
        for ( int i = 0; i < length_of_ssid; i++ ) {
          EEPROM.write(i + 1, str_ssid.charAt(i));
        }
        Serial.print((int)EEPROM.read(0));
        for ( int i = 1; i < length_of_ssid + 1; i++ ) {
          Serial.print((char)EEPROM.read(i));
        }
        Serial.println("");
        EEPROM.commit();
      }
      else if ( commands[1].equals("SETPASS") ) {
        str_pass = commands[2];
        length_of_pass = str_pass.length();

        EEPROM.write(length_of_ssid + 1, length_of_pass);
        for ( int i = length_of_ssid + 1; i < length_of_ssid + length_of_pass + 1; i++ ) {
          EEPROM.write(i + 1, str_pass.charAt(i - (length_of_ssid + 1)));
        }

        Serial.print((int)EEPROM.read(length_of_ssid + 1));
        for ( int i = (length_of_ssid + 1); i < (length_of_ssid + 1 + length_of_pass + 1); i++ ) {
          Serial.print((char)EEPROM.read(i));
        }
        EEPROM.commit();
      }
      else if ( commands[1].equals("GETEEPROM") ) {
        for ( int i = 0; i < 512; i++ ) {
          Serial.print((char)EEPROM.read(i));
        }
      }
      else if ( commands[1].equals("GETSTATUS") ) {
        Serial.print("SSID:");
        Serial.println(str_ssid);

        Serial.print("PASS:");
        Serial.println(str_pass);

        if ( WiFi.isConnected() ) {
          Serial.print("IP address:");
          Serial.println(WiFi.localIP());
          Serial.printf("UDP server on port % d\n", localPort);
        }
        else {
          Serial.println("Device is not connected to WiFi.");
        }
      }
      else if ( commands[1].equals("RESET") ) {
        Serial.println("");
        Udp.stop();
        Serial.println("Reconnecting...");
        WiFi.disconnect(true);
        delay(100);



        networkStart();
        //Udp.begin(localPort);
      }
    }
  }


  // if there's data available, read a packet
  int packetSize = Udp.parsePacket();
  if (packetSize) {
    pixels.setPixelColor(0, pixels.Color(255, 255, 255));
    pixels.show();
    /*
      Serial.printf("<header>Received packet of size % d from % s: % d to % s: % d) < / header > ",
                  packetSize,
                  Udp.remoteIP().toString().c_str(), Udp.remotePort(),
                  Udp.destinationIP().toString().c_str(), Udp.localPort(),
                  ESP.getFreeHeap());
    */
    // read the packet into packetBufffer
    int n = Udp.read(packetBuffer, UDP_TX_PACKET_MAX_SIZE);
    packetBuffer[n] = 0;
    Serial.print(packetBuffer);
    delay(30);
    pixels.setPixelColor(0, pixels.Color(0, 255, 0));
    pixels.show();

    // send a reply, to the IP address and port that sent us the packet we received
    //Udp.beginPacket(Udp.remoteIP(), Udp.remotePort());
    //Udp.write(ReplyBuffer);
    //Udp.endPacket();
  }

}

/*
  test (shell/netcat):
  --------------------
  nc -u 192.168.esp.address 8888
*/
