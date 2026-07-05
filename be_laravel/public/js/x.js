(function () {
    const input = document.querySelector('[data-popup-image-input]');
    const button = document.querySelector('[data-popup-submit]');
    const note = document.querySelector('[data-popup-note]');

    if (!input) return;

    function setFile(file) {
        const dt = new DataTransfer();
        dt.items.add(file);
        input.files = dt.files;
    }

    function loadImage(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = function (event) {
                const img = new Image();
                img.onload = function () { resolve(img); };
                img.onerror = reject;
                img.src = event.target.result;
            };
            reader.onerror = reject;
            reader.readAsDataURL(file);
        });
    }

    function toBlob(canvas, quality) {
        return new Promise((resolve) => {
            canvas.toBlob(resolve, 'image/webp', quality);
        });
    }

    async function makeSmall(file) {
        if (!file || !file.type || !file.type.startsWith('image/')) return file;
        if (file.size <= 1700 * 1024) return file;

        const img = await loadImage(file);
        const limit = 1100;
        const scale = Math.min(1, limit / Math.max(img.width, img.height));
        const width = Math.max(1, Math.round(img.width * scale));
        const height = Math.max(1, Math.round(img.height * scale));

        const canvas = document.createElement('canvas');
        canvas.width = width;
        canvas.height = height;
        const ctx = canvas.getContext('2d');
        ctx.clearRect(0, 0, width, height);
        ctx.drawImage(img, 0, 0, width, height);

        let quality = 0.9;
        let blob = await toBlob(canvas, quality);
        while (blob && blob.size > 1700 * 1024 && quality > 0.55) {
            quality -= 0.08;
            blob = await toBlob(canvas, quality);
        }

        if (!blob || blob.size >= file.size) return file;
        return new File([blob], 'popup-' + Date.now() + '.webp', { type: 'image/webp' });
    }

    input.addEventListener('change', async function () {
        const file = input.files && input.files[0] ? input.files[0] : null;
        if (!file) return;

        const oldSize = file.size;
        if (note) note.textContent = 'Menyiapkan gambar...';
        input.disabled = true;
        if (button) button.disabled = true;

        try {
            const prepared = await makeSmall(file);
            setFile(prepared);
            const beforeKb = Math.round(oldSize / 1024);
            const afterKb = Math.round(prepared.size / 1024);
            if (note) {
                note.textContent = prepared.size < oldSize
                    ? 'Gambar otomatis diperkecil: ' + beforeKb + ' KB menjadi ' + afterKb + ' KB.'
                    : 'Gambar siap diupload: ' + afterKb + ' KB.';
            }
        } catch (e) {
            if (note) note.textContent = 'Gambar siap diupload.';
        } finally {
            input.disabled = false;
            if (button) button.disabled = false;
        }
    });
})();
