import java.util.regex.*;

class AlbumArtExtractor{
    private byte[] readAsByteList(FileInputStream stream, int length){
        byte[] buf = new byte[length];
        try{
            stream.read(buf, 0, length);
        }
        catch (Exception e){
            e.getStackTrace();
        }
        return buf;
    }

    private String readAsAsciiString(FileInputStream stream, int length){
        byte[] data = this.readAsByteList(stream, length);
        String res = "";
        for (byte x : data) res += Character.toString((char)x);

        return res;
    }

    //Read %count% bytes from the FileStream. Return as long since 4bytes array needs unsigned integer.
    //Big-endian
    private long readAsLong(FileInputStream stream){
        //Read just 1byte default
        return this.readAsLong(stream, 1);
    }

    private long readAsLong(FileInputStream stream, int count){
        byte[] buf = this.readAsByteList(stream, count);
        byte[] res = new byte[8];
        for (byte x : buf) x = 0x00;
        for (byte x : res) x = 0x00;
        
        for (int i = 0; i < count; i++) res[8-count+i] = buf[i];
        return ByteBuffer.wrap(res).getLong();
    }

    //Check whether tag data is ID3v2.3 or not.
    //If the mp3 file has "Extended header", return false;
    public boolean checkVersion(String fPath){
        try{
            FileInputStream f = new FileInputStream(fPath);
            String magicID = this.readAsAsciiString(f, 3);
            long version = this.readAsLong(f, 2);
            long extendedFlag = this.readAsLong(f, 1);
            
            f.close();
            return (magicID.equals("ID3") && version == 0x0300 && (extendedFlag & 0x40) == 0);
        }
        catch (Exception e){
            return false;
        }
    }

    private int[] getJpegSize(FileInputStream rabbit){
        int[] res = new int[2];
        for (int x : res) x = 0;
        byte last = 0, now = 0;
        boolean quit = false;

        while(true) {
            last = now;
            try {
                now = byte(rabbit.read());
            }
            catch (Exception e){
                println("Hello");
            }
            res[0]++;
            if (last == byte(-1) && now == byte(-40)) {
                res[0] -= 2;
                break;
            }
        }
        while(true){
            last = now;
            try{
                now = byte(rabbit.read());
            }
            catch (Exception e){
                println("Hello");
            }
            res[1]++;

            if (last == byte(-1) && now == byte(-39)) {
                println(last, now);
                quit = true;
            }
            
            if (quit == true && last == byte(-39) && now == byte(-1)){
                println(last, now);
                quit = false;
            }
            else if (quit == true && last == byte(0) && now == byte(0)){
                println(last, now);
                res[1] -= 2;
                break;
            }
        }

        return res;
    }

    private int[] getPngSize(FileInputStream rabbit){
        int[] res = new int[2];
        int a = 0, b = 0;
        for (int x : res) x = 0;
        long[] temp = new long[8];
        long[] beginFlag = {0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};
        long[] endFlag = {0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82};

        while(true){
            for (int i = 1; i < 8; i++) temp[i-1] = temp[i];
            temp[7] = this.readAsLong(rabbit, 1);
            a++;

            boolean match = true;
            for (int i = 0; i < 8; i++) if (temp[i] != beginFlag[i]) match = false;
            
            if (match){
                res[0] -= 8;
                break;
            }
        }

        while(true){
            for (int i = 1; i < 8; i++) temp[i-1] = temp[i];
            temp[7] = this.readAsLong(rabbit, 1);
            b++;

            boolean match = true;
            for (int i = 0; i < 8; i++) if (temp[i] != endFlag[i]) match = false;
            
            if (match){
                break;
            }
        }

        return new int[]{a, b};
    }

    private int extract(String fPath){
        try {
            FileInputStream rabbit = new FileInputStream(fPath), turtle = new FileInputStream(fPath);
            try{
                rabbit.skip(10);
                turtle.skip(10);

                long count = 1;
                while(true){
                    String frameName = this.readAsAsciiString(rabbit, 4);
                    boolean validName = Pattern.compile("^[A-Z0-9]+$").matcher(frameName).matches();
                    if (validName == false) break;
                    int frameSize = int(this.readAsLong(rabbit, 4));

                    
                    //Skip flags
                    rabbit.skip(2);
                    turtle.skip(10);

                    //If looking frame is "Album Picture" frame
                    if (frameName.equals("APIC")){
                        println("APIC header found");

                        rabbit.skip(7);
                        turtle.skip(10);
                        String fileFormat = this.readAsAsciiString(rabbit, 3);
                        boolean isJpeg = (fileFormat.equals("jpe")||fileFormat.equals("jpg"));

                        //Create skiptable
                        int[] slTable = new int[2];
                        if (fileFormat.equals("jpe") || fileFormat.equals("jpg")) {
                            println("AlbumArtFormat: jpeg");
                            slTable = this.getJpegSize(rabbit);
                        }
                        else if (fileFormat.equals("png")) {
                            println("AlbumArtFormat: png"); 
                            slTable = this.getPngSize(rabbit);
                        }
                        else {
                            println("Something Strange found");
                            rabbit.close();
                            turtle.close();
                            return -1;
                        }
                        println(slTable);

                        turtle.skip(slTable[0]);
                        // ArrayList<Byte> img = new ArrayList<Byte>();
                        // byte last = 0, now = 0;

                        // while(true){
                        //     last = now;
                        //     now = byte(turtle.read());
                        //     img.add(now);
                        //     if (last == byte(-1) && now == byte(0xD9)){
                        //         break;
                        //     }
                        // }

                        // byte[] data = new byte[img.size()];
                        // for (int i = 0; i < img.size(); i++) {
                        //     data[i] = img.get(i);
                        // }

                        // for (int i = 0; i < slTable[1]; i++){
                        //     img[i] = byte(turtle.read());
                        // }

                        byte[] img = new byte[slTable[1]];

                        println(img.length, img[0], img[1], img[img.length-2], img[img.length-1]);
                        img = this.readAsByteList(turtle, slTable[1]);
                        
                        String filename = (isJpeg?"out.jpeg":"out.png");
                        FileOutputStream out = new FileOutputStream(sketchPath(filename));
                        out.write(img);
                        out.close();
                        out = null;

                        rabbit.close();
                        turtle.close();

                        return (isJpeg?1:2);
                    }

                    //Skip to the end of the frame.
                    rabbit.skip(frameSize);
                    turtle.skip(frameSize);
                    
                    //Out Of Range
                    if (count > 74) {
                        println("APIC header not found");
                        break;
                    }
                    count++;
                }

                rabbit.close();
                turtle.close();
            }
            catch (Exception ei){
                rabbit.close();
                turtle.close();
            }
        }
        catch (Exception e){
            println(e.getStackTrace());
            e.getStackTrace();
        }
        return -1;
    }

    public int generateAlbumArt(String fPath){
        /* Return Values
            -1: Errors
             1: Jpeg
             2: Png
        */
        if (checkVersion(fPath) == false) return -1;
        else return this.extract(fPath);
    }
}