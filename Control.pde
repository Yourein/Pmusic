//Dummy class for lamda in processing3
abstract class fn {
  abstract void func();
}

class Button {
  private fn onClicked;
  private PImage buttonTexture;
  private int x, y, width, height;

  Button(int _x, int _y, int _width, int _height, PImage texture, fn clickHandler) {
    x = _x;
    y = _y;
    width = _width;
    height = _height;
    buttonTexture = texture;
    onClicked = clickHandler;
  }

  public void drawButton() {
    image(buttonTexture, x, y, width, height);
  }

  public void changeTexture(PImage texture) {
    buttonTexture = texture;
  }

  public void mouseClicked() {
    if (mouseX < x+width && mouseX > x && mouseY < y+height && mouseY > y) {
      this.onClicked.func();
    }
  }
}

void volumeUp() {
  gain = min(0, gain+1);
  player.setGain(gain);
}

void volumeDown() {
  gain = max(-64, gain-1);
  player.setGain(gain);
}

void PlayPause() {
  if (playListBuf.get(playInd).pauseState() == false) {
    playListBuf.get(playInd).PlayPause();
    player.pause();
  } else {
    playListBuf.get(playInd).PlayPause();
    player.play();
  }
}

void toggleMute() {
  if (isMuted == false) {
    isMuted = true;
    player.setGain(-64);
  } else {
    isMuted = false;
    player.setGain(gain);
  }
}

void Eject() {
  changingTrack = true;
  player.pause();
  changingTrack = false;
  loopStatus = 0;
  resetPlayer(playListBuf.size());
}

void nextTrack() {
  changingTrack = true;
  player.pause();
  resetPlayer(playInd+1);
  changingTrack = false;
}

void rewindTrack() {
  if (player.position() <= 5000) {
    changingTrack = true;
    player.pause();
    resetPlayer(max(0, playInd-1));
    changingTrack = false;
  } else {
    player.rewind();
  }
}

void toggleLoop() {
  loopStatus += 1;
  loopStatus %= 3;

  if (loopStatus == 0) buttons.get(6).changeTexture(loadImage("./data/noroop.png"));
  else if (loopStatus == 1) buttons.get(6).changeTexture(loadImage("./data/rooping.png"));
  else if (loopStatus == 2) buttons.get(6).changeTexture(loadImage("./data/roopingone.png"));
}

void toggleInfo() {
  panelStatus += 1;
  panelStatus %= 2;

  if (panelStatus != 1) {
    for (SlidePanel x : queuePanels) x.resetCount();
  }
}

void skipTenSec() {
  player.cue(player.position()+10000);
}

void backTenSec() {
  player.cue(player.position()-10000);
}
