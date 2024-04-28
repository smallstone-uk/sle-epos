component
{
    /**
     * Redirects to the given URL.
     *
     * @return any
     */
    public any function to(string path = '/')
    {
        if (startsWith(path, 'http')) {
            location(path, false);
        } else {
            location(getUrl(path), false);
        }
    }

    /**
     * Redirects to the previous page.
     *
     * @return any
     */
    public any function back()
    {
        location(session.redirect.previous, false);
    }

    /**
     * Makes a post request to the given URL with the given form data.
     * Expects response content to be JSON.
     * Returns a deserialized structure of the JSON.
     *
     * @return any
     */
    public any function post(required string path, struct data = {})
    {
        return deserializeJSON(new App.Framework.Legacy().httpRequest(path, 'post', data).fileContent);
    }
}
