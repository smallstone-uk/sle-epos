component
{
    /**
     * Constructor method for auth.
     *
     * @return any
     */
    public any function init()
    {
        if (!structKeyExists(session, 'auth')) {
            session.auth = {};
        }

        return this;
    }

    /**
     * Returns the authenticated user.
     *
     * @return any
     */
    public any function user()
    {
        return session.auth;
    }

    /**
     * Checks whether the web user is a guest (unauthenticated).
     *
     * @return boolean
     */
    public boolean function guest()
    {
        if (!structKeyExists(session, 'auth')) {
            return true;
        }

        return structIsEmpty(session.auth);
    }

    /**
     * Updates the authenticated model.
     *
     * @return any
     */
    public any function update(required any user)
    {
        if (!structKeyExists(session.auth, 'getPrimaryKeyField')) {
            return this;
        }

        var currentID = session.auth[session.auth.getPrimaryKeyField()];
        var newID = user[user.getPrimaryKeyField()];

        if (currentID == newID) {
            session.auth = user;
        }

        return this;
    }

    /**
     * Refreshes the authenticated model.
     *
     * @return any
     */
    public any function refresh()
    {
        if (!structKeyExists(session, 'auth')) {
            return this;
        }

        if (!structKeyExists(session.auth, 'refresh')) {
            return this;
        }

        session.auth = session.auth.refresh();

        return this;
    }

    /**
     * Handles user login through the auth controller.
     *
     * @return boolean
     */
    public boolean function login(any targetUser = {}, boolean remember = false)
    {
        try {
            var userRecord = new App.Controllers.AuthController().tokenLogin(this.token(), targetUser, remember);
            session.auth = userRecord;
            return true;
        } catch (any error) {
            writeDumpToFile(error);
            return false;
        }
    }

    /**
     * Unauthenticates the user.
     *
     * @return any
     */
    public any function logout(boolean clearCookie = true)
    {
        if (this.guest()) {
            return;
        }

        session.auth = {};

        if (clearCookie) {
            if (structKeyExists(cookie, 'cfuser')) {
                structDelete(cookie, cfuser);
            }

            new App.Framework.Legacy().cookie('cfuser', '', now());
        }
    }

    /**
     * Sends an activation email to the authenticated user.
     *
     * @return void
     */
    public void function sendActivationEmail(required any user, required string email, string subject = 'Activate your account')
    {
        if (structIsEmpty(user)) {
            return;
        }

        if (!structKeyExists(application, 'mail')) {
            throw('Cannot find mail settings in application.');
            return;
        }

        var post = new mail();
        var token = new App.Controllers.AuthController().getActivationToken(user);

        saveContent variable = 'postContent' {
            view('emails.activation', {
                'user' = user,
                'token' = token
            });
        }

        post.setTo(email);
        post.setFrom(application.mail.from);
        post.setSubject(subject);
        post.setType('html');
        post.setAttributes(
            server = application.mail.server,
            username = application.mail.username,
            password = application.mail.password
        );

        post.send(body = postContent);
    }

    /**
     * Gets the token from cookie or a new one.
     *
     * @return string
     */
    public string function token()
    {
        return (structKeyExists(cookie, 'cfuser')) ? cookie.cfuser : lCase(createUUID());
    }
}
