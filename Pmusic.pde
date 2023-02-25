import ddf.minim.*;
import ddf.minim.analysis.*;

import java.nio.file.Path;
import java.nio.file.Paths;

import java.io.File;
import javax.swing.JFileChooser;
import javax.swing.filechooser.*;

Minim minim = new Minim(this);             
AudioPlayer player;              
FFT fft;
FFT fLeft, fRight;
int gain = -15;                 
float specSize;
float initBand;
int stepCount;
final int frameXBegin = 50, frameYBegin = 10;
final int frameWidth = 590, frameHeight = 430;
int barWidth;         

boolean isSelected = false;
boolean isMuted = false;
boolean begin = false;
boolean selectRequest = true;
boolean changingTrack = false;
int panelStatus = 0;
int loopStatus = 0;

final int FPS = 15;
final int DIV = 1;

PFont tFont;
PFont bFont;
PFont lFont;
PImage AlbumArt;
PImage specImg;
PImage emptyAlbumArt;

ArrayList<SlidePanel> infoPanels = new ArrayList<SlidePanel>(3);
ArrayList<SlidePanel> queuePanels = new ArrayList<SlidePanel>(10);
ArrayList<Button> buttons = new ArrayList<Button>();
ArrayList<Song> playListBuf;
SlidePanel queueTitle = new SlidePanel("QUEUE", frameXBegin+10, 35, 5);
int playInd = 0;

final int bandHz[] =  {30, 80, 125, 200, 250, 300, 400, 500, 750, 1000, 1200, 1500, 1900, 2400, 3000, 4600, 5800, 7000, 11000, 12000, 15000, 18000, 22000};
final int MAXBAND = bandHz.length;
final int[] bgColor = {30, 30, 30};
final int[] textOrange = {245, 179, 10};

void setup() {
  size(1280, 630);

  tFont = createFont("./data/JF-Dot-Shinonome14.ttf", 26);
  bFont = createFont("./data/JF-Dot-Shinonome14B.ttf", 26);
  lFont = createFont("./data/JF-Dot-Shinonome14B.ttf", 40);
  emptyAlbumArt = loadImage("./data/noimage.png");
  specImg = loadImage("./data/spec.png");

  for (int i = 0; i < 3; i++) infoPanels.add(new SlidePanel("", frameXBegin+frameWidth+30, 30+(40*i), 10));
  for (int i = 0; i < 10; i++) queuePanels.add(new SlidePanel("", frameXBegin+100, 100+(40*i), 16));

  //Buttons
  buttons.add(new Button(1075, 20, 80, 80, loadImage("./data/playpause.png"), new fn() {
    public void func() {
      PlayPause();
    }
  }
  ));
  buttons.add(new Button(975, 20, 80, 80, loadImage("./data/rewind.png"), new fn() {
    public void func() {
      rewindTrack();
    }
  }
  ));
  buttons.add(new Button(1175, 20, 80, 80, loadImage("./data/forward.png"), new fn() {
    public void func() {
      nextTrack();
    }
  }
  ));
  buttons.add(new Button(975, 249, 80, 80, loadImage("./data/mute.png"), new fn() {
    public void func() {
      toggleMute();
    }
  }
  ));
  buttons.add(new Button(1075, 249, 80, 80, loadImage("./data/volumedown.png"), new fn() {
    public void func() {
      volumeDown();
    }
  }
  ));
  buttons.add(new Button(1175, 249, 80, 80, loadImage("./data/volumeup.png"), new fn() {
    public void func() {
      volumeUp();
    }
  }
  ));
  buttons.add(new Button(975, 133, 80, 80, loadImage("./data/noroop.png"), new fn() {
    public void func() {
      toggleLoop();
    }
  }
  ));
  buttons.add(new Button(1075, 365, 180, 80, loadImage("./data/toggleinfo.png"), new fn() {
    public void func() {
      toggleInfo();
    }
  }
  ));
  buttons.add(new Button(1175, 133, 80, 80, loadImage("./data/gop10.png"), new fn() {
    public void func() {
      skipTenSec();
    }
  }
  ));
  buttons.add(new Button(1075, 133, 80, 80, loadImage("./data/gom10.png"), new fn() {
    public void func() {
      backTenSec();
    }
  }
  ));
  buttons.add(new Button(975, 365, 80, 80, loadImage("./data/eject.png"), new fn() {
    public void func() {
      Eject();
    }
  }
  ));

  textFont(tFont);
  frameRate(FPS);
}

void draw() {   
  background(bgColor);

  if (player == null) {
    if (isSelected == false && selectRequest == true) {
      playListBuf = selectMusic();
      if (playListBuf.size() > 0) isSelected = true;
      selectRequest = false;
    } else if (isSelected == false && selectRequest == false) {
      textAlign(CENTER, CENTER);
      text("No Music Loaded! Press L to Choose File(s).", width/2, height/2);
      textAlign(LEFT, LEFT);
    } else if (isSelected == true && selectRequest == false) {
      resetPlayer(0);
    }
  } else {
    if (begin == true) {
      drawTrackInfo();
      createMargin();

      //Do every in DIV [frameCount]
      if (frameCount%DIV == 0) {
        fft.forward(player.mix);
        fLeft.forward(player.left);
        fRight.forward(player.right);
      }

      //Draw main panel
      switch (panelStatus) {
      case 0:
        drawHistogram();
        drawRMS();
        break;
      case 1:
        drawQueue();
        break;
      };

      //Draw some player status
      drawGain();
      drawStatus();
      drawTimeElapsed();
      drawClock();

      for (Button btn : buttons) btn.drawButton();

      if (changingTrack == false && playListBuf.get(playInd).pauseState() == false && player.isPlaying() == false) {
        if (loopStatus != 2) resetPlayer(playInd+1);
        else rewindTrack();
      }
    }
  }
}

void keyPressed() {
  if ((key == 'L' || key == 'l') && isSelected == false && selectRequest == false) {
    selectRequest = true;
  }

  if (key == 'P' || key == 'p' && begin == true) {
    PlayPause();
  }

  if (key == 'E' || key == 'e' && begin == true) {
    Eject();
  }

  if (key == 'L' || key == 'l' && begin == true) {
    skipTenSec();
  }

  if (key == 'H' || key == 'H' && begin == true) {
    backTenSec();
  }

  if (key == CODED && keyCode == UP && begin == true) {
    volumeUp();
  }
  if (key == CODED && keyCode == DOWN && begin == true) {
    volumeDown();
  }

  if (key == 'M' || key == 'm' && begin == true) {
    toggleMute();
  }

  if (key == CODED && keyCode == RIGHT && begin == true) {
    nextTrack();
  }

  if (key == CODED && keyCode == LEFT && begin == true) {
    rewindTrack();
  }

  if (key == 'R' || key == 'r' && begin == true) {
    toggleLoop();
  }
}

void mouseClicked() {
  if (begin == true) for (Button btn : buttons) btn.mouseClicked();
}
