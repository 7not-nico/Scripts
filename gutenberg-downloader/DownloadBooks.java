import java.io.*;
import java.net.*;
import java.nio.file.*;
import java.util.concurrent.*;

public class DownloadBooks {
    public static void main(String[] args) {
        ExecutorService executor = Executors.newFixedThreadPool(5);
        for (int i = 1; i <= 100; i++) {
            final int id = i;
            executor.submit(() -> downloadBook(id));
        }
        executor.shutdown();
        try {
            executor.awaitTermination(1, TimeUnit.HOURS);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        System.out.println("Download complete.");
    }

    private static void downloadBook(int id) {
        String filename = "book_" + id + ".txt";
        Path path = Paths.get(filename);
        if (Files.exists(path)) return;
        String url = "https://www.gutenberg.org/cache/epub/" + id + "/pg" + id + ".txt";
        try {
            HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
            conn.setRequestMethod("GET");
            if (conn.getResponseCode() == 200) {
                try (BufferedReader in = new BufferedReader(new InputStreamReader(conn.getInputStream()));
                     BufferedWriter out = Files.newBufferedWriter(path)) {
                    String line;
                    while ((line = in.readLine()) != null) {
                        out.write(line);
                        out.newLine();
                    }
                }
            }
        } catch (Exception e) {
            // silent
        }
    }
}