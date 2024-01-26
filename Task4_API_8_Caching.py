from dash import Dash, dcc, Output, Input, State, html
import dash_bootstrap_components as dbc
import plotly.graph_objects as go
import json
import snowflake.connector
from pymongo import MongoClient
from flask import Flask
from dash import callback_context
from flask_caching import Cache
import pandas as pd

def main():

    # Initialize Flask application and link it to Dash
    server = Flask(__name__)
    app = Dash(__name__, external_stylesheets=[dbc.themes.LUX], server=server)

    # Initialize Flask-Caching
    cache = Cache(app.server, config={'CACHE_TYPE': 'simple'})

    # Replace these with your Snowflake credentials
    snowflake_credentials = {
        "account": "elugxls-ox45694",
        "user": "SUSHMAMENGANI",
        "password": "Srinidhi7",
        "warehouse": "COMPUTE_WH",
        "database": "ECONOMIC_DATA",
        "schema": "PUBLIC"
    }

    # Function to query Snowflake and return data as JSON with caching
    @cache.memoize(timeout=60)  # Set timeout (in seconds) based on your needs
    def query_snowflake_json_cached(query):
        conn = snowflake.connector.connect(
            user=snowflake_credentials["user"],
            password=snowflake_credentials["password"],
            account=snowflake_credentials["account"],
            warehouse=snowflake_credentials["warehouse"],
            database=snowflake_credentials["database"],
            schema=snowflake_credentials["schema"]
        )
        cur = conn.cursor()
        cur.execute(query)
        results = cur.fetchall()
        cur.close()
        conn.close()

        # Check if results are empty
        if not results:
            return None

        # Convert results to a list of dictionaries (JSON)
        columns = [desc[0] for desc in cur.description]
        data = [dict(zip(columns, row)) for row in results]

        return data

    # Replace these with your MongoDB credentials
    mongodb_credentials = {
        "host": "localhost",
        "port": 27017,
        "database": "covid_19",
        "collection": "Task3"
    }

    # Connect to MongoDB
    mongo_client = MongoClient(mongodb_credentials["host"], mongodb_credentials["port"])
    mongo_db = mongo_client[mongodb_credentials["database"]]
    comments_collection = mongo_db[mongodb_credentials["collection"]]

    mytitle = dcc.Markdown(id='page-title', children='# Welcome to My Data Analysis Dashboard', style={'height': '50px', 'margin-top': '20px'})
    mygraph = dcc.Graph(figure={}, style={'width': '900px', 'height': '500px', 'margin': 'auto'})
    dropdown = dcc.Dropdown(options=[], value=None, clearable=False)
    query_input = dcc.Input(
        id='query-input',
        type='text',
        value="""
        Select * from ECONOMIC_DATA.PUBLIC.GLOBAL_ECONOMY WHERE GDPCAP = '9'
        """,
        style={'width': '100%'}
    )
    run_query_btn = dbc.Button("Run Query", id="run-query-btn", color="primary", className="text-left")

    # Add a modal for adding comments
    comment_modal = dbc.Modal(
        [
            dbc.ModalHeader("Add Comment"),
            dbc.ModalBody(
                [
                    dbc.Input(id="comment-author", type="text", placeholder="Your Name", style={'margin-bottom': '20px'}),
                    dcc.Textarea(id="comment-textarea", placeholder="Type your comment here", rows=5),
                ]
            ),
            dbc.ModalFooter(
                [
                    dbc.Button("Submit", id="submit-comment-btn", color="primary"),
                    dbc.Button("Close", id="close-comment-btn", color="secondary"),
                ]
            ),
        ],
        id="comment-modal",
    )

    # Dummy dropdown to resolve callback exception
    dummy_dropdown = dcc.Dropdown(id='dropdown', options=[], value='Population', multi=False, style={'display': 'none'})

    
    app.layout = dbc.Container([
        dbc.Row([
            dbc.Col([dummy_dropdown], width=12)
        ]),
        dbc.Row([
            dbc.Col([
                dcc.Markdown(id='page-title', children='# Welcome to My Data Analysis Dashboard', style={'height': '50px', 'margin-top': '20px'}),
                dummy_dropdown,
            ], width=12)
        ]),
        dbc.Row([
            dbc.Col([
                dbc.Row([
                    dbc.Col([query_input], width=8, className="mb-3"),
                    dbc.Col([run_query_btn], width=4, className="mb-3"),
                ]),
                dbc.Row([
                    dbc.Col([dropdown], width=6),
                    dbc.Col([comment_modal], width=6, style={"display": "none"}),
                ], className="mt-3"),
            ], width=12)
        ]),
        dbc.Row([
            dbc.Col([mygraph], width=12, className="mt-4")
        ]),
        dbc.Row([
            dbc.Col([
                html.Div("By Sushma Mengani", style={"font-size": "14px", "color": "#888", "text-align": "center", "margin-top": "20px"})
            ], width=12)
        ]),
    ], fluid=True)


    # Callback
    @app.callback(
        [
            Output(mygraph, 'figure'),
            Output('page-title', 'children'),
            Output("comment-modal", "is_open"),
            Output("comment-textarea", "value"),
            Output(dropdown, 'options'),
        ],
        [
            Input(mygraph, 'clickData'),
            Input(dropdown, 'value'),
            Input("submit-comment-btn", "n_clicks"),
            Input("close-comment-btn", "n_clicks"),
            Input("run-query-btn", "n_clicks"),
        ],
        [
            State("comment-author", "value"),
            State("comment-textarea", "value"),
            State("comment-modal", "is_open"),
            State("query-input", "value"),
            State("dropdown", "options"),
        ]
    )
    @cache.memoize(timeout=60)  # Set timeout (in seconds) based on your needs
    def update_graph_and_comments_cached(click_data, selected_column, submit_btn_clicks, close_btn_clicks, run_query_btn_clicks, author_name, comment_text, is_comment_modal_open, user_query, dropdown_options):
        try:
            global comments_collection  # Declare comments_collection as global

            # Check if the callback is triggered by a country click
            is_country_click = click_data and 'points' in click_data

            # Determine the query to execute
            if run_query_btn_clicks and user_query:
                query_to_execute = user_query
            else:
                query_to_execute = """
                Select * from ECONOMIC_DATA.PUBLIC.GLOBAL_ECONOMY WHERE GDPCAP = '9'
                """

            print(f"Executing query: {query_to_execute}")

            # Query Snowflake and get data in JSON format
            data_json = query_snowflake_json_cached(query_to_execute)

            # Handle case when no data is retrieved or structure is unexpected
            if not data_json or not data_json[0]:
                raise Exception("No data or unexpected data structure")

            # Update dropdown options
            new_dropdown_options = [{'label': col, 'value': col} for col in data_json[0].keys()]

            # Ensure selected_column is not None
            selected_column = selected_column or new_dropdown_options[0]['value']

            # Convert data to DataFrame for visualization
            df = pd.DataFrame(data_json)

            # Determine appropriate x-axis based on the available columns
            x_axis_column = 'date' if 'date' in df.columns else df.columns[0]

            # Create a line plot using plotly.graph_objects
            fig = go.Figure(data=go.Scatter(
                x=df[x_axis_column],
                y=df[selected_column],
                mode='lines',
                marker=dict(color='#A100FF'),
                name=selected_column
            ))

            # Update layout
            fig.update_layout(
                title_text=f'{selected_column} over Time',
                xaxis_title=x_axis_column.capitalize(),
                yaxis_title=selected_column,
                showlegend=True
            )

            clicked_country_iso = None
            is_comment_modal_open_new = is_comment_modal_open

            # Handle click on line plot
            if is_country_click:
                clicked_country_iso = click_data['points'][0]['location']
                is_comment_modal_open_new = True

            # Handle comment submission
            ctx = callback_context
            if ctx.triggered_id == "submit-comment-btn" and comment_text and clicked_country_iso:
                # Get full country name
                clicked_country = next((entry[x_axis_column] for entry in data_json if entry[x_axis_column] == clicked_country_iso), None)
                if clicked_country:
                    # Create comment entry
                    country_comment = {
                        "country": clicked_country,
                        "column": selected_column,
                        "author": author_name,
                        "comment": comment_text,
                    }
                    comments_collection.insert_one(country_comment)
                    # Hide the comment modal after submission
                    is_comment_modal_open_new = False

            # Handle comment modal close button
            if ctx.triggered_id == "close-comment-btn":
                is_comment_modal_open_new = False

            return fig, f'# Welcome to {selected_column} Analysis Dashboard', is_comment_modal_open_new, "", new_dropdown_options
        except Exception as e:
            print(f"Error: {str(e)}")  # Debug line
            return go.Figure(), f"Error: {str(e)}", is_comment_modal_open, "", dropdown_options
    
    return app  # Return the app object

# Run Flask and Dash apps
if __name__ == '__main__':
    app = main()
    app.run_server(debug=True, port=8054) 

'''
for running in EC2 instance change the last line of the code to this which is including the host 
if __name__ == '__main__':
    app.run_server(debug=True, host='0.0.0.0', port=8054)
'''

