class SlidePanel {
  private String message;
  private boolean needShift = false; //Overflow flag
  private int shifted = 0; //Shift counter
  private int initCount = 0; //To wait before starting string shift.
  private boolean initShift = false;
  
  private int panelWidth; //To check string overflow

  private int panelXPos;
  private int panelYPos;

  SlidePanel(String s, int XPos, int YPos, int pWidth){
    this.message = s;
    this.panelXPos = XPos;
    this.panelYPos = YPos;
    this.panelWidth = pWidth;
    init();
  }

  private void init(){
    this.needShift = (message.length() > this.panelWidth);
    this.shifted = 0;
    this.initCount = 0;
    this.initShift = false;

    return;
  }

  public void changeMessage(String s){
    this.message = null;
    this.message = s;
    init();

    return;
  }

  public String getMessage(){
    return this.message;
  }

  public void incCount(){
    if (this.needShift == false) return;

    this.initCount++;
    if (this.initShift == false && this.initCount > FPS*5) this.initShift = true;
    else if (this.initShift == true){
      if (this.initCount%FPS == 0) this.shifted++;
      if (this.shifted > message.length()) this.shifted = 0;
    }

    return;
  }

  public void drawPanel(){
    textAlign(CENTER, CENTER);
    for (int i = 0; i < min(this.panelWidth, message.length()); i++){
      if (i+this.shifted < message.length()){
        text(message.charAt(i+this.shifted), this.panelXPos+(28*i), this.panelYPos);
      }
    }
    textAlign(LEFT, LEFT);

    return;
  }

  public int getPanelWidth(){
    return panelWidth;
  }

  public void resetCount(){
    this.initShift = false;
    this.initCount = 0;
    this.shifted = 0;
    
    return;
  }
};

void draw_histogram(){
  image(specImg, frameXBegin, frameYBegin+frameHeight, frameWidth, 30);
  stroke(0);
  for (int index = 0; index < MAXBAND; index++) {
      //Fix FFT output for db scale.
      float bandData = 6 * getDecibel(max((float)fft.getBand(int(bandHz[index]/initBand)), 1.0));
      if (bandData <= 0) continue;

      fill(255);
      rect(index*barWidth+frameXBegin, frameYBegin+frameHeight, barWidth, -frameHeight*bandData/300);
  }
  noStroke();

  return;
}

void createMargin(){
  noStroke();
  fill(bgColor);
  rect(0, 0, frameWidth, frameHeight);
  rect(frameXBegin, frameYBegin, frameWidth, frameHeight);

  stroke(255);
  line(frameXBegin+frameWidth, 0, frameXBegin+frameWidth, height);
  line(frameXBegin+frameWidth, 460, width, 460);

  return;
}

void drawTrackInfo(){
  textFont(bFont);
  fill(textOrange);
  for (SlidePanel x : infoPanels) {
    x.incCount();
    x.drawPanel();
  }
  
  if (AlbumArt.height > AlbumArt.width) image(AlbumArt, frameXBegin+frameWidth+15, 150, AlbumArt.width*300/AlbumArt.height, 300);
  else image(AlbumArt, frameXBegin+frameWidth+15, 150, 300, AlbumArt.height*300/AlbumArt.width);

  fill(255);
  textFont(tFont);

  return;
}

void drawRMS(){
  float lRMS = 0, rRMS = 0;
  float lt = 0, rt = 0;
  final float mValue = 23;
  
  final int[] rmsGreen = {100, 230, 100};
  final int[] rmsYellow = {230, 230, 0};
  final int[] rmsRed = {230, 100, 100};

  stroke(0);

  for (int index = 0; index < MAXBAND; index++){
    float lTemp = getDecibel(max((float)fLeft.getBand(int(bandHz[index]/initBand)), 1));
    float rTemp = getDecibel(max((float)fRight.getBand(int(bandHz[index]/initBand)), 1));

    lt += lTemp;
    rt += rTemp;
    lRMS += lTemp*lTemp;
    rRMS += rTemp*rTemp;
  }

  lRMS = sqrt(lRMS/MAXBAND);
  rRMS = sqrt(rRMS/MAXBAND);

  if (lRMS/mValue > 0.9) fill(rmsRed);
  else if (lRMS/mValue > 0.6) fill(rmsYellow);
  else fill(rmsGreen);
  rect(frameXBegin, frameHeight+75, (frameWidth-30)*min(lRMS/mValue, 1.00), 25);
  
  if (rRMS/mValue > 0.9) fill(rmsRed);
  else if (rRMS/mValue > 0.6) fill(rmsYellow);
  else fill(rmsGreen);
  rect(frameXBegin, frameHeight+125, (frameWidth-30)*min(rRMS/mValue, 1.0), 25);

  fill(255);
  noStroke();

  return;
}

void drawTimeElapsed(){
  long trackLength = player.length();
  long timeElapsed = player.position();

  String txt = String.format("%-16s : %02d:%02d/%02d:%02d", "ELAPSED / LENGTH",timeElapsed/(1000*60), (timeElapsed%(1000*60))/1000, trackLength/(1000*60), (trackLength%(1000*60))/1000);
  text(txt, frameXBegin+frameWidth+30, 570);

  return;
}

void drawGain(){
  String pfs = String.format("%-16s : ", "VOLUME");
  if (isMuted == true || gain <= -64) text(pfs+"MUTED", frameXBegin+frameWidth+30, 510);
  else text(pfs+String.format("%03d [db]", gain), frameXBegin+frameWidth+30, 510);

  return;
}

void drawStatus(){
  String rsStr = "";
  if (loopStatus == 0) rsStr = "NO LOOP";
  else if (loopStatus == 1) rsStr = "LOOP PLAYLIST";
  else if (loopStatus == 2) rsStr = "LOOP THIS SONG";
  text(String.format("%-16s : ", "STATUS")+(playListBuf.get(playInd).pauseState()?"PAUSING":"PLAYING")+", "+rsStr, frameXBegin+frameWidth+30, 540);

  return;
}

void drawClock(){
  text(String.format("%-16s : %02d:%02d:%02d", "COMPUTER TIME",hour(), minute(), second()), frameXBegin+frameWidth+30, 600);

  return;
}

void drawQueue(){
  textFont(lFont);
  fill(textOrange);
  queueTitle.incCount();
  queueTitle.drawPanel();
  fill(255);

  textFont(tFont);

  for (SlidePanel x : queuePanels) {
    x.incCount();
    x.drawPanel();
  }

  for (int i = playInd; i < min(playInd+10, playListBuf.size()); i++){
    String showTxt;
    if (i == playInd) showTxt = "Now : ";
    else showTxt = String.format("%03d : ", i+1);
    text(showTxt, frameXBegin, 112+(40*(i-playInd)));
  }

  return;
}