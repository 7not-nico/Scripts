const https = require('https');

const fs = require('fs');

async function downloadBook(id) {

    const filename = `book_${id}.txt`;

    if (fs.existsSync(filename)) return;

    const url = `https://www.gutenberg.org/cache/epub/${id}/pg${id}.txt`;

    return new Promise((resolve) => {

        https.get(url, (res) => {

            if (res.statusCode !== 200) return resolve();

            let data = '';

            res.on('data', chunk => data += chunk);

            res.on('end', () => {

                fs.writeFileSync(filename, data);

                resolve();

            });

        }).on('error', () => resolve());

    });

}

async function main() {

    const promises = [];

    for (let i = 1; i <= 100; i++) {

        promises.push(downloadBook(i));

    }

    await Promise.all(promises);

    console.log('Download complete.');

}

main();