component
{
    /**
     * Constructor method for media.
     *
     * @return any
     */
    public any function init(string file = '')
    {
        if (file != '') {
            if (fileExists(getDataDir(file))) {
                this.file = getDataDir(file);
            } else {
                throw('File #getDataDir(file)# does not exist.');
                return;
            }
        }

        return this;
    }

    /**
     * Uploads the given form field to the given relative data path;
     *
     * @return any
     */
    public any function upload(required string field, required string path, string accept = '')
    {
        if (!structKeyExists(form, field)) {
            throw("Form field '#field#' does not exist.");
            return this;
        }

        var file = fileUpload(
            getDataDir(path, true),
            field/*,
            accept,
            'makeUnique',
            false*/
        );

        this.file = '#file.serverDirectory#/#file.serverFile#';

        return this;
    }

    /**
     * Renames the file.
     * If no new name is given, a random UID is used.
     *
     * @return any
     */
    public any function rename(string name = '')
    {
        if (name == '') {
            name = lCase(createUUID());
        }

        var extension = listLast(this.file, '.');
        var dir = listToArray(this.file, '/');
        arrayDeleteAt(dir, arrayLen(dir));

        var newPath = '#arrayToList(dir, "/")#/#name#.#extension#';

        fileMove(
            this.file,
            newPath
        );

        this.file = newPath;

        return this;
    }

    /**
     * Gets the name of the file.
     *
     * @return string
     */
    public string function name()
    {
        var file = listLast(replace(this.file, '\', '/', 'all'), '/');
        return listFirst(file, '.');
    }

    /**
     * Gets the file's extension.
     *
     * @return string
     */
    public string function extension()
    {
        return listLast(this.file, '.');
    }

    /**
     * Gets the full name of the file including the extension.
     *
     * @return string
     */
    public string function fullname()
    {
        return '#this.name()#.#this.extension()#';
    }

    /**
     * Gets the resized name of the file.
     *
     * @return any
     */
    public any function resizedName(required any size)
    {
        if (isArray(size)) {
            return '#arrayToList(size, "_")#-#this.fullname()#';
        } else {
            return '#size#-#this.fullname()#';
        }
    }

    /**
     * Gets the directory path.
     *
     * @return string
     */
    public string function directory()
    {
        var items = listToArray(replace(this.file, '\', '/', 'all'), '/');
        arrayDeleteAt(items, arrayLen(items));
        return stripSlashes(arrayToList(items, '/'));
    }

    /**
     * Gets the relative directory path.
     *
     * @return string
     */
    public string function relativeDirectory()
    {
        return stripSlashes(mid(this.directory(), len(getDataDir()), 1000));
    }

    /**
     * Gets the path to the file with the given size.
     *
     * @return any
     */
    public any function resizedPath(required any size)
    {
        return '#this.relativeDirectory()#/#this.resizedName(size)#';
    }

    /**
     * Gets the relative public directory of the given source file.
     *
     * @return string
     */
    public string function publicDirectory()
    {
        var path = convertChars(this.relativeDirectory(), '\', '/');
        return stripSlashes(stripIndex(path, 1, '/'));
    }

    /**
     * Checks whether the given file is the source file.
     * Source files exist in /data/secure.
     *
     * @return boolean
     */
    public boolean function isSource()
    {
        var path = convertChars(this.relativeDirectory(), '\', '/');
        return lCase(listFirst(path, '/')) == 'secure';
    }

    /**
     * Gets the URL of the file.
     *
     * @return string
     */
    public string function url(any size = 0)
    {
        if (!isNumeric(size) && isValid('string', size) && len(size)) {
            // Get size from environment
            size = env('media.#size#', 256);
        }

        if (size > 0) {
            if (this.isSource()) {
                var path = '#this.publicDirectory()#/#this.resizedName(size)#';

                if (fileExists(getDataDir(path))) {
                    return getUrl('/data/#stripSlashes(path)#');
                } else {
                    var file = this.copy(this.publicDirectory());
                    file.resize(size);
                    file.deleteSource();
                    return file.url(size);
                }
            }

            var path = this.resizedPath(size);

            if (fileExists(getDataDir(path))) {
                return getUrl('/data/#stripSlashes(path)#');
            } else {
                this.resize(size);
                return this.url(size);
            }
        }

        var uri = mid(this.file, len(getDataDir()), 1000);
        return getUrl('/data/#stripSlashes(uri)#');
    }

    /**
     * Gets the relative data path of the file.
     *
     * @return string
     */
    public string function relativePath()
    {
        return stripSlashes(mid(this.file, len(getDataDir()), 1000));
    }

    /**
     * Resizes the image.
     *
     * @return any
     */
    public any function resize(required numeric width, numeric height = -1)
    {
        if (height == -1) {
            this.resizeSquare(width);
        } else {
            var dest = this.resizedPath([width, height]);
            var image = imageRead(this.file);
            imageScaleToFit(image, width, height, 'mediumPerformance');
            imageWrite(image, getDataDir(dest), 1);
        }

        return this;
    }

    /**
     * Resizes the image to a square.
     *
     * @return any
     */
    public any function resizeSquare(required numeric size)
    {
        var image = imageRead(this.file);
        var info = imageInfo(image);
        var dest = this.resizedPath(size);

        if (info.width < size || info.height < size) {
            if (info.width >= info.height) {
                imageResize(image, "", size, 'mediumPerformance');
            } else {
                imageResize(image, size, "", 'mediumPerformance');
            }
        } else {
            if (info.height >= info.width) {
                imageScaleToFit(image, size, "", 'mediumPerformance');
            } else {
                imageScaleToFit(image, "", size, 'mediumPerformance');
            }
        }

        info = imageInfo(image);

        if (info.height >= size) {
            imageCrop(image, 0, ((info.height / 2) - (size / 2)), size, size);
        } else {
            imageCrop(image, ((info.width / 2) - (size / 2)), 0, size, size);
        }

        imageWrite(image, getDataDir(dest), 0.75);
        return this;
    }

    /**
     * Copies the file to the given relative directory.
     * Returns a new media object of the new file.
     *
     * @return any
     */
    public any function copy(required string destination)
    {
        var destPath = '#stripSlashes(destination)#/#this.fullname()#';

        if (fileExists(getDataDir(destPath))) {
            return media(destPath);
        }

        fileCopy(
            this.file,
            getDataDir(destination, true)
        );

        return media('#stripSlashes(destination)#/#this.fullname()#');
    }

    /**
     * Deletes the source file, but not its resized counterparts.
     *
     * @return any
     */
    public any function deleteSource()
    {
        if (fileExists(this.file)) {
            fileDelete(this.file);
        }

        return this;
    }
}
