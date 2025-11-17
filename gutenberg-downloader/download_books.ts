const https = require('https');

const fs = require('fs');

async function downloadBook(id: number): Promise<void> {

    const filename: string = `book_${id}.txt`;

    if (fs.existsSync(filename)) return;

    const url: string = `https://www.gutenberg.org/cache/epub/${id}/pg${id}.txt`;

    return new Promise<void>((resolve) => {

        https.get(url, (res: any) => {

            if (res.statusCode !== 200) return resolve();

            let data: string = '';

            res.on('data', (chunk: any) => data += chunk);

            res.on('end', () => {

                fs.writeFileSync(filename, data);

                resolve();

            });

        }).on('error', () => resolve());

    });

}

async function main(): Promise<void> {

    const promises: Promise<void>[] = [];

    for (let i = 1; i <= 100; i++) {

        promises.push(downloadBook(i));

    }

    await Promise.all(promises);

    console.log('Download complete.');

}

main();