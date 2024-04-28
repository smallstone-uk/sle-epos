component extends = "Model"
{
    variables.datasource = getDatasource(true);
    variables.table = application.mvc.migrationTableName;
    variables.model = "Framework.Migration";
}
