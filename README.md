# docli - Docker Compose Central Management
The `docli` script is a useful tool that allows you to manage multiple docker compose stacks with a single command. Using an 'inventory' file, you can organize your stacks into groups and perform operations on them in a streamlined way.

## Desing
1. Validates that the 'inventory' file exists
2. Parses the arguments using a while to iterate over them and save the parameters as flags
3. Parses an 'inventory' file to understand the organization of your docker compose groups and stacks using associative arrays for easy access to the specific groups/stacks
4. Does another validation round to check that the combination of arguments makes sense and can be executable
5. Then determines the list of groups/stacks to apply the action
6. Apply the operations `up` (start), `down` (stop), and `create` to the specific groups/stacks

## Usage
You can use the tool using the following patterns:
./docli [OPTION] ... [DIRECTORY] ...

## Options

- `--version`: Output version information and exit
- `--all`: Apply the command to all groups in the inventory
- `--context[=CTX]`: Inventory group to apply the command
- `--help`: Display the help message and exit

## Commands

- `create` : Create a new directory
- `up` : Executes 'docker-compose up -d'
- `down` : Executes 'docker-compose down'

Remember to make sure that the `inventory` file exists in the same location as the script and that it follows the right format for the script to understand your stack configurations.

## Version
Current version of the script is '1.0'.

## Contribution
Feel free to fork this project, make some changes, then submit a pull request.

## License
This project is licensed under the MIT License.