class TextBox4Caption
{
  TextBox4Caption() {
    text_all = new StringBuilder("");
    text_all_wrapped = new StringBuilder("");
    caption = new ArrayList<String>();
    max_number_of_wrap = 5;
    line_height = 24;
    width_text_box = 200;
    is_scrolling = false;
    scroll_speed = 0.5;
    max_buffer_size = 4000;
  }


  void draw(float _x, float _y) {
    if ( is_scrolling ) {
      scroll_y = scroll_y - scroll_speed;
      if ( scroll_y <= 0 ) {
        is_scrolling = false;
        scroll_y = 0;
      }
    }
    //y_bottom_line = height - 80;
    float y_draw_start = y_bottom_line;// - textHeight(text_all_wrapped.toString(), line_height);
    canvas_caption.text(text_all_wrapped.toString(), _x, y_draw_start+scroll_y);
  }

  String wrap()
  {
    if( text_all.length() <= 0 ){
      return "";
    }
    int pos = 0;
    String str_tmp = "";
    ArrayList<Integer>line_length = new ArrayList<Integer>(0);
    int number_of_wrap = 0;
    float height_wrapped_previous = textHeight(text_all_wrapped.toString(), line_height);
    text_all_wrapped.delete(0, text_all_wrapped.length());
    while ( true ) {   

      if ( pos >= text_all.length()) {
        text_all_wrapped.append(str_tmp);
        break;
      }

      if ( canvas_caption.textWidth(str_tmp) >= width_text_box   ) {
        str_tmp = str_tmp +text_all.charAt(pos);
        text_all_wrapped.append(str_tmp);
        line_length.add(str_tmp.length());
        text_all_wrapped.append("\n");
        number_of_wrap++;
        str_tmp = "";
      } else if ( text_all.charAt(pos) == '\n' ) {
       
        text_all_wrapped.append(str_tmp);
         line_length.add(str_tmp.length());
        text_all_wrapped.append("\n");
        str_tmp = "";
        number_of_wrap++;
      } else {
        str_tmp = str_tmp + text_all.charAt(pos);
        
      //  println(str_tmp);
      }
      
      pos++;
    }
    //println(text_all.toString());


    scroll_y = textHeight(text_all_wrapped.toString(), line_height)-height_wrapped_previous;
    /*
    if ( number_of_wrap > max_number_of_wrap) {
      for( int i = 0; i < (number_of_wrap-max_number_of_wrap); i++ ){
      text_all.delete(0, line_length.get(i));
      }
    }
*/
    y_bottom_line = height - 100 -textHeight(text_all_wrapped.toString(), line_height);
    is_scrolling = true;

    /*
    for ( int i = 0; i < line_length.size(); i++ ) {
     println("["+i+"]: ", line_length.get(i));
     }
     */

    return text_all_wrapped.toString();
  }

  void setScrollSpeed(float _speed)
  {
    scroll_speed = _speed;
  }
  void setWidth(float _w) {
    width_text_box = _w;
  }
  void addString(String _str) {
    if ( _str.equals("$改行$")  ) {
      _str = "\n";
    }
    if( text_all.length() > 3000 ){
      text_all.delete(0, text_all.length());
    }
    text_all.append(_str);
    wrap();
    //println(text_all_wrapped.toString());
  }
  void addChar(char _c) {
    addString(str(_c));
  }

  void setLineHeight(float _line_height)
  {
    line_height = _line_height;
  }

  void clear()
  {
    caption.clear();
    text_all.delete(0, text_all.length());
    text_all_wrapped.delete(0, text_all_wrapped.length());
  }

  int getHowManyCharacter(char _c)
  {
    int start_index = 0;
    int count = 0;

    while ( (start_index = text_all.indexOf("\n", start_index+1)) > 0 ) {
      count++;
    }
    return count;
  }

  float textHeight(String _str, float _line_height)
  {
    float h = textAscent()+textDescent();
    int start_index = 0;
    int count = 0;

    while ( (start_index = _str.indexOf("\n", start_index+1)) > 0 ) {
      count++;
    }
    h = (textAscent()+textDescent())*(count+1) + (_line_height)*(count+1);
    h = (_line_height)*(count+1);
    return h;
  }

  void setYBottomLine(float _y)
  {
    y_bottom_line = _y;
  }

  int font_size;
  StringBuilder text_all;
  StringBuilder text_all_wrapped;
  float width_text_box;
  float line_height;
  int max_number_of_wrap;
  ArrayList<String>caption;
  boolean is_scrolling;
  float scroll_y;
  float scroll_speed;
  float y_bottom_line;
  int max_buffer_size;
}
