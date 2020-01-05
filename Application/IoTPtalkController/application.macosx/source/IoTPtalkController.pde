import hypermedia.net.*;
import controlP5.*;
import processing.serial.*;
import codeanticode.syphon.*;
Serial serialPort;
final int BAUD_RATE = 74880;
IoTPtalk iotptalk = new IoTPtalk();
Encoder encoder;
UDP udp;

DummyText dummy_text;

final String IP = "";
final int PORT = 6711; // 受信側ポート番号

PFont font_caption;
PFont font_icon;

PGraphics canvas_caption;
TextBox4Caption caption = new TextBox4Caption();

ControlP5 cp5;
Textarea myTextarea;
Println console;

DropdownList serialPortsList;
String[] portNames;
boolean is_serial_open = false;

int slider_text_size, slider_text_size_previous;
int slider_line_height, slider_line_height_previous;
int bg_alpha;
float slider_scroll_speed;
int height_previous;
int width_previous;
String SSID;
String Password;
boolean auto_text;


boolean isParameterChanged()
{
  // window resize check
  if ( height_previous != int(height) || width_previous != int(width) ) {
    height_previous = int(height);
    width_previous = int(width);
    return true;
  }
  if ( slider_text_size_previous != slider_text_size ) {
    slider_text_size_previous = slider_text_size;
    return true;
  }
  if ( slider_line_height != slider_line_height_previous ) {
    slider_line_height_previous = slider_line_height;
    return true;
  }

  return false;
}

SyphonServer server;

void setup() {
  dummy_text = new DummyText();
  size(1280, 500, P2D);
  surface.setResizable(true);
  //pixelDensity(displayDensity());
  frameRate(60);
  //canvas_caption.pixelDensity(displayDensity());
  canvas_caption = createGraphics(width, height, P2D);
  server = new SyphonServer(this, "IoTPTalk");  
  portNames = Serial.list();

  int font_size = 10;
  cp5 = new ControlP5(this);
  cp5.enableShortcuts();
  Group g_settings = cp5.addGroup("Settings")
    .setPosition(20, 20)
    .setBackgroundHeight(300)                
    .setBackgroundColor(color(20, 200))
    .setFont(createFont("arial", font_size))
    .setWidth(310)
    ;
  cp5.addSlider("slider_text_size")
    .setRange(12, 72)
    .setPosition(10, 10)
    .setSize(150, 20 )
    .setValue(24)
    .setFont(createFont("arial", font_size))
    .setGroup(g_settings)
    ;
  cp5.addSlider("slider_line_height")
    .setRange(1, 72)
    .setPosition(10, 10+25)
    .setSize(150, 20 )
    .setValue(24)
    .setFont(createFont("arial", font_size))
    .setGroup(g_settings)
    ;
  cp5.addSlider("slider_scroll_speed")
    .setRange(0.2, 2.0)
    .setPosition(10, 10+25*2)
    .setSize(150, 20 )
    .setValue(1.0)
    .setFont(createFont("arial", font_size))
    .setGroup(g_settings)
    ;
  cp5.addToggle("auto_text")
    .setPosition(10, 10+25*3)
    .setSize(60, 20)
    .setValue(false)
    .setFont(createFont("arial", font_size))
    .setGroup(g_settings)
    ;
  cp5.addBang("clear_text")
    .setPosition(10+60+10, 10+25*3)
    .setSize(60, 20)
    .setFont(createFont("arial", font_size))    
    .setGroup(g_settings)
    ;
  cp5.addColorWheel("color", 10, 0, 100 )
    .setPosition(10, 10+25*5)
    .setGroup(g_settings)
    .setFont(createFont("arial", font_size))    
    .setRGB(color(255, 255, 255));

 cp5.addColorWheel("bg_color", 10, 0, 100 )
    .setPosition(10+120, 10+25*5)
    .setGroup(g_settings)
    .setFont(createFont("arial", font_size))
    .setRGB(color(0,0, 0,100));
    
    
  cp5.addSlider("bg_alpha")
    .setRange(0, 255)
    .setPosition(10+120, 10+25*10)
    .setSize(100, 20 )
    .setValue(200.0)
    .setFont(createFont("arial", font_size))
    .setGroup(g_settings)
    ;

  Group g_device_settings = cp5.addGroup("Device Settings")
    .setPosition(350, 20)
    .setBackgroundHeight(130)                
    .setBackgroundColor(color(20, 200))
    .setFont(createFont("arial", font_size))
    .setWidth(310)
    ;

  cp5.addBang("restart")
    .setPosition(120+100+10, 10+25*3)
    .setSize(60, 20)
    .setFont(createFont("arial", font_size))
    .setGroup(g_device_settings)
    ;

  cp5.addTextfield("SSID")
    .setPosition(10, 10+25*3)
    .setFont(createFont("arial", font_size))
    .setSize(100, 20)
    .setGroup(g_device_settings)
    .setAutoClear(false)
    ;
  cp5.addTextfield("Password")
    .setPosition(10+100+10, 10+25*3)
    .setFont(createFont("arial", font_size))
    .setSize(100, 20)
    .setGroup(g_device_settings)
    .setAutoClear(false)
    ;
  // create a DropdownList

  serialPortsList = cp5.addDropdownList("serial_ports")
    .setPosition(10, 10)
    .setWidth(290)
    .setHeight(500)
    .setBarHeight(20)
    .setItemHeight(20)
    .setFont(createFont("arial", font_size))
    .setGroup(g_device_settings)
    .setOpen(false)
    ;

  myTextarea = cp5.addTextarea("txt")
    .setPosition(680, 20)
    .setSize(330, 130)
    .setFont(createFont("arial", font_size))
    .setLineHeight(10)
    .setColor(color(200))
    .setColorBackground(color(20, 200))
    .setColorForeground(color(255, 100));                  
  ;


  //console = cp5.addConsole(myTextarea);

  for (int i = 0; i < portNames.length; i++) serialPortsList.addItem(portNames[i], i);  


  udp = new UDP(this, 6711);
  udp.log( true ); 
  udp.listen( true );
  println("UDP Buffer Size: " + udp.getBuffer());
  encoder = new Encoder();
  encoder.setup();

  // 日本語フォントを作成し指定する
  font_caption = createFont("ipaexg.ttf", 32, true);
  font_icon = createFont("Font Awesome 5 Brands-Regular-400.otf", 48, true);

  textFont(font_caption);
  textSize(slider_text_size); // フォントサイズ指定：48
  textAlign(LEFT, TOP);

  canvas_caption.textFont(font_caption);
  canvas_caption.textSize(slider_text_size); // フォントサイズ指定：48
  canvas_caption.textAlign(LEFT, TOP);
}


void draw() { 
  background(255);
  canvas_caption.strokeWeight(10);
  canvas_caption.stroke(255, 0, 0);
  canvas_caption.fill(cp5.get(ColorWheel.class, "color").getRGB());
  if ( is_serial_open  && iotptalk.available() > 0 ) {
    String str_get = iotptalk.getText();
    caption.addString(str_get);
  }
  if ( dummy_text.isTextAppendTiming() ) {
    caption.addString(dummy_text.getNewLine());
    //println(dummy_text.getNewLine());
  }


  if ( isParameterChanged() ) {
    caption.wrap();
  }


  caption.setLineHeight(slider_line_height);
  caption.setWidth(width-150); 
  caption.scroll_speed = slider_scroll_speed;



  canvas_caption.beginDraw();
  canvas_caption.textFont(font_caption);
  canvas_caption.textSize(slider_text_size);
  canvas_caption.textLeading(slider_line_height);
  //canvas_caption.background(0, 0, 0, bg_alpha);
  canvas_caption.background(cp5.get(ColorWheel.class, "bg_color").getRGB(), bg_alpha);
  caption.draw(50, height/2);
  canvas_caption.endDraw();
  server.sendImage(canvas_caption);
  image(canvas_caption, 0, 0);//, width, height);

  //caption.draw(50, height/2);




  //line(0, height - slider_line_height*1.5, width, height-slider_line_height*1.5);
  text(typed_text.toString(), 50, height - slider_line_height*1.5);

  textFont(font_icon);
  textSize(48);
  if ( is_serial_open ) {
    String str = new String("\uF287");
    text(str, width-slider_text_size-10, 0);
  } else {
    String str = new String("\uF838");
    text(str, width-slider_text_size-10, 0);
  }

  textFont(font_caption);
  textSize(slider_text_size);
}



String message = "";
void receive( byte[] data, String ip, int port ) {
  if ( is_serial_open ) {
    return;
  }
  for ( int i = 0; i < data.length; i++ ) {
    if ( data[i] > 0  ) {
      message = message + char(data[i]);
    } else {
      message = message + encoder.getUtfString(data[i], data[i+1]);
      println(message);
      i++;
    }
  }
  println("UDP Message: ["+message+"]");
  println("UDP Message length: "+ textWidth(message));
  println("UDP Message size: " + message.length());
  caption.addString(message);

  message = "";
}

StringBuilder typed_text = new StringBuilder();
void keyPressed()
{

  if ( key == RETURN || key == ENTER ) { 
    if ( typed_text.length() == 0 ) {
      typed_text.append("\n");
    } 
    caption.addString(typed_text.toString());
    typed_text.delete(0, typed_text.length());
  } else if ( key == BACKSPACE ) {
    if ( typed_text.length() > 0 )typed_text.deleteCharAt(typed_text.length()-1);
  } else {
    typed_text.append(key);
  }
}


void controlEvent(ControlEvent theEvent) {
  if (theEvent.isGroup()) {
    println("got an event from group "
      +theEvent.getGroup().getName()
      +", isOpen? "+theEvent.getGroup().isOpen()
      );
  } else if (theEvent.isController()) {
    println("got something from a controller "
      +theEvent.getController().getName()
      );
    if ( theEvent.getController().getName().equals("auto_text") ) {
      if ( int(theEvent.getController().getValue()) == 1  ) {
        dummy_text.play();
      } else {
        dummy_text.stop();
      }
    } else if ( theEvent.getController().getName().equals("clear_text")) {
      caption.clear();
    } else if ( theEvent.getController().getName().equals("serial_ports")) {
      int num = int(theEvent.getController().getValue());
      println(portNames[num]);
      serialPort = new Serial(this, portNames[num], 74880);
      is_serial_open = true;
      iotptalk.set(serialPort);//portNames[num]);
      println(iotptalk.getStatus());
      cp5.get(Textfield.class, "SSID").setText(iotptalk.getSSID());
      cp5.get(Textfield.class, "Password").setText(iotptalk.getPassword());
    } else if ( theEvent.getController().getName().equals("restart")) {
      iotptalk.reset();
    }
  }
}
