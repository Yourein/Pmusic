Minim mInspector = new Minim(this);
AudioPlayer aInspector;
AudioMetaData meta;

AlbumArtExtractor ext = new AlbumArtExtractor();

final String[] winArg1 = {"del", sketchPath("out.jpeg")};
final String[] winArg2 = {"del", sketchPath("out.png")};

class Song {
  private String track;

  private String mTitle;
  private String aTitle;
  private String tArtist;

  private boolean pause = false;

  Song(File _track) {
    track = _track.getAbsolutePath();
    println(track);
    mInspector.debugOff();
    aInspector = mInspector.loadFile(_track.getAbsolutePath(), 1024);

    meta = aInspector.getMetaData();
    mTitle = meta.title();
    aTitle = meta.album();
    tArtist = meta.author();

    //Release memories
    meta = null;
    aInspector = null;
    mInspector.stop();
  }

  public File getFile() {
    return new File(track);
  }

  public String getAbsolutePath() {
    return track;
  }

  public boolean pauseState() {
    return this.pause;
  }

  public void PlayPause() {
    this.pause = !this.pause;
  }

  public String getTrackArtist() {
    return this.tArtist;
  }

  public String getTrackTitle() {
    return this.mTitle;
  }

  public String getAlbumTitle() {
    return this.aTitle;
  }
};

int createAlbumArt(String filepath) {
  launch(winArg1);
  launch(winArg2);

  //Wait CMD
  delay(300);
  return ext.generateAlbumArt(filepath);
}
