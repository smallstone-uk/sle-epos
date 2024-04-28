component extends = "Controller"
{
    /**
     * Constructor method for AuthController.
     *
     * @return any
     */
    public any function init()
    {
        // Create token table if it doesn't exist
        if (!this.tokenTableExists()) {
            this.createTokenTable();
        }

        // Add token field to user table
        // if it doesn't exist
        if (!this.tokenFieldExists()) {
            this.createTokenField();
        }

        return this;
    }

    /**
     * Creates the token table.
     *
     * @return any
     */
    public any function createTokenTable()
    {
        var table = schema('remember_tokens');
        table.increments('id');
        table.timestamps();
        table.string('token').unique();
        table.create();
    }

    /**
     * Checks whether the token table exists.
     *
     * @return any
     */
    public any function tokenTableExists()
    {
        return new QueryBuilder(getDatasource(true))
            .add("SHOW TABLES LIKE 'remember_tokens'")
            .run()
            .recordcount != 0;
    }

    /**
     * Creates the token field.
     *
     * @return any
     */
    public any function createTokenField()
    {
        var table = schema(this.model().getTable());
        table.integer('remember_token').nullable();
        table.foreign('remember_token').references('remember_tokens', 'id').onDelete('set null');
        table.update();
    }

    /**
     * Checks whether the token field exists.
     *
     * @return any
     */
    public any function tokenFieldExists()
    {
        return structKeyExists(this.model(), 'remember_token');
    }

    /**
     * Activates the account with the given token.
     *
     * @return any
     */
    public any function activate(required string token)
    {
        var authModel = new App.Controllers.AuthController().model();
        var user = authModel
            .where('activation_token', token)
            .take(1)
            .get();

        if (structIsEmpty(user)) {
            return view('layouts.index|errors.500');
        } else {
            user.skipAuth().activate();
            redirect().to('/');
        }
    }

    /**
     * Gets a new activation token for the given user.
     *
     * @return any
     */
    public any function getActivationToken(required any user)
    {
        var token = lCase(createUUID());

        if (!structKeyExists(user, 'activation_token')) {
            var table = schema(user.getTable());
            table.string('activation_token').nullable();
            table.update();
        }

        user = user.refresh();
        user.activation_token = token;
        user.skipAuth();
        user.save();

        return token;
    }

    /**
     * Attempts to login the user using the given token.
     *
     * @return any
     */
    public any function tokenLogin(string token = '', any targetUser = {}, boolean remember = false)
    {
        try {
            if (token != '') {
                // Delete old token
                if (!structIsEmpty(targetUser) && len(targetUser.remember_token) > 0) {
                    var existingToken = new App.Framework.Token()
                        .where('id', targetUser.remember_token)
                        .take(1)
                        .getArray();

                    if (!arrayIsEmpty(existingToken)) {
                        existingToken[1].delete();
                    }
                }

                // Find token
                var authModel = this.model();
                var tokenRecord = new App.Framework.Token()
                    .where('token', token)
                    .take(1)
                    .getArray();

                if (arrayIsEmpty(tokenRecord)) {
                    if (!structIsEmpty(targetUser)) {
                        // Create new token and link to user
                        var newToken = new App.Framework.Token().save({'token' = token});
                        targetUser.remember_token = newToken.id;
                        targetUser.skipAuth();
                        targetUser.save();

                        if (remember) {
                            // Only store cookie if remember is true
                            // Still creates a token in database
                            new App.Framework.Legacy().createTokenCookie(token);
                        }

                        return targetUser;
                    } else {
                        return {};
                    }
                } else {
                    // Get user with given token
                    tokenRecord = tokenRecord[1];
                    var user = authModel
                        .where('remember_token', tokenRecord.id)
                        .take(1)
                        .getArray();

                    if (arrayIsEmpty(user)) {
                        return {};
                    } else {
                        return user[1];
                    }
                }
            }

            return {};
        } catch (any error) {
            writeDumpToFile(error);
        }
    }
}
