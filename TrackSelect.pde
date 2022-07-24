final FileNameExtensionFilter Filter = new FileNameExtensionFilter("Music or Playlist", "mp3", "wav", "txt");

ArrayList<Song> selectMusic() {
  //Create file choosing dialog
  JFileChooser filechooser = new JFileChooser();
  filechooser.setMultiSelectionEnabled(true);
  filechooser.addChoosableFileFilter(Filter);
  filechooser.setFileFilter(Filter);
  filechooser.setAcceptAllFileFilterUsed(false);

  //Await response
  int selected = filechooser.showOpenDialog(null);

  //If "OPEN" clicked.
  ArrayList<Song> res = new ArrayList<Song>();
  if (selected == JFileChooser.APPROVE_OPTION) {
    File[] files = filechooser.getSelectedFiles();
    for (int i = 0; i < files.length; i++) {
      String fExt = files[i].getAbsolutePath().substring(files[i].getAbsolutePath().length()-3);

      if (fExt.equals("txt")){
        String[] temp = loadStrings(files[i].getAbsolutePath());

        for (String x : temp){
          File tempFile = new File(x);
          if (tempFile.exists() == false) continue;
          Song tempSong = new Song(tempFile);
          res.add(tempSong);
        }
      }
      else {
        Song temp = new Song(files[i]);
        res.add(temp);
      }
    }

    files = null;
  }

  filechooser = null;
  //If no files selected or "CANCEL" clicked, return 0-length static array
  return res;
}

void loadMusic(Song selection) {
  try {
    //int aResult = createAlbumArt(selection.getFile().getAbsolutePath());
    int aResult = 1;
    //Wait file-update
    delay(300);

    //LoadMusic
    player = minim.loadFile(selection.getFile().getAbsolutePath(), 1024);
    player.setGain(gain);

    //Loading AlbumArt
    AlbumArt = emptyAlbumArt;
    try{
      if (aResult == 1) AlbumArt = loadImage("out.jpeg");
      else if (aResult == 2) AlbumArt = loadImage("out.png");
    }
    catch (Exception e){
      AlbumArt = emptyAlbumArt;
    }

    //Setup FFT
    fft = new FFT(player.bufferSize(), player.sampleRate()); 
    fLeft = new FFT(player.bufferSize(), player.sampleRate());
    fRight = new FFT(player.bufferSize(), player.sampleRate());
    specSize = fft.specSize();
    fft.window(FFT.HAMMING);
    fLeft.window(FFT.HAMMING);
    fRight.window(FFT.HAMMING);

    initBand = fft.getBandWidth();
    barWidth = frameWidth/MAXBAND;

    //Setup infoPanels;
    infoPanels.get(0).changeMessage(selection.getTrackTitle());
    infoPanels.get(1).changeMessage(selection.getTrackArtist());
    infoPanels.get(2).changeMessage(selection.getAlbumTitle());

    //Start playing
    player.play();
    begin = true;
    frameCount = 0;

    System.gc();
  }
  catch (NullPointerException e) {
    isSelected = false;
    return;
  }
}

void resetPlayer(int nextInd) {
  //Release memories
  minim.stop();
  AlbumArt = null;
  player = null;
  begin = false;
  fft = null;
  fLeft = null;
  fRight = null;

  System.gc();

  //Go to next song
  playInd = nextInd;
  for (int i = playInd; i < playInd+10; i++){
    if (i < playListBuf.size()) queuePanels.get(i-playInd).changeMessage(playListBuf.get(i).getTrackTitle()+" / "+playListBuf.get(i).getAlbumTitle());
    else queuePanels.get(i-playInd).changeMessage("");
  }

  if (playInd < playListBuf.size()) {
    loadMusic(playListBuf.get(playInd));
  } else {
    playInd = 0;
    if (loopStatus == 1){
      loadMusic(playListBuf.get(playInd));
    }
    else {
      isSelected = false;
      selectRequest = true;
      
      playListBuf.clear();
      playListBuf = null;
      System.gc();
    }
  }
}