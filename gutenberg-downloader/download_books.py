import requests
import os
import threading
import queue

def download_book(id):
    filename = f"book_{id}.txt"
    if os.path.exists(filename):
        return
    url = f"https://www.gutenberg.org/cache/epub/{id}/pg{id}.txt"
    try:
        response = requests.get(url)
        if response.status_code == 200:
            with open(filename, 'w') as f:
                f.write(response.text)
    except:
        pass

q = queue.Queue()
for i in range(1, 101):
    q.put(i)

def worker():
    while not q.empty():
        id = q.get()
        download_book(id)
        q.task_done()

threads = []
for _ in range(5):
    t = threading.Thread(target=worker)
    t.start()
    threads.append(t)

for t in threads:
    t.join()

print("Download complete.")