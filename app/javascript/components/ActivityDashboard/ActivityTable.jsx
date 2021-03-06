import React, {Component, Fragment} from 'react';
import BootstrapTable from 'react-bootstrap-table-next';
import ToolkitProvider, {Search} from 'react-bootstrap-table2-toolkit';
import * as PropTypes from 'prop-types';
import {Panel, Grid} from "react-bootstrap";
import DataPairField from "../ProjectTeams/Show/DataPairField";
import paginationFactory from 'react-bootstrap-table2-paginator';

class ActivityTable extends Component {

    columns = [
        {
            dataField: 'event_type',
            text: 'Event Type',
        }, {
            dataField: 'github_repo',
            text: 'Repository',
            formatter: row => this.renderRepoUrl(row)
        }, {
            dataField: 'url',
            text: 'URL',
            formatter: row => this.renderEventUrl(row)
        }, {
            dataField: 'created_at',
            text: 'Date Created',
        }
    ];

    expandRow = {
        renderer: row => (
            <Fragment>
                <Grid componentClass="px-0">
                    <DataPairField fieldName={'Commit Message'} fieldValue={row.message}/>
                    <DataPairField fieldName={'Branch'} fieldValue={row.branch}/>
                    <DataPairField fieldName={'Files Changed'} fieldValue={row.files_changed.toString()}/>
                    <DataPairField fieldName={'Commit Hash'} url={row.url} fieldValue={row.commit_hash}/>
                    <DataPairField fieldName={'Commit Timestamp'} fieldValue={row.commit_timestamp}/>
                </Grid>
            </Fragment>
        ),
        showExpandColumn: true
    }

    renderRepoUrl(row) {
        return (
            <a href={row.url}>{row.name}</a>
        );
    }

    renderEventUrl(row) {
        return (
            <a href={row}>View on GitHub</a>
        );
    }

    render() {
        return (
            <Fragment>
                <Panel>
                    <Panel.Heading>
                        <Panel.Title>Activity Stream</Panel.Title>
                    </Panel.Heading>
                    <Panel.Body>
                        <BootstrapTable columns={this.columns} data={this.props.activityStream} keyField={'id'}
                                        expandRow={this.expandRow} striped hover pagination={paginationFactory()} />
                    </Panel.Body>
                </Panel>
            </Fragment>
        );
    }
}

ActivityTable.propTypes = {
    activityStream: PropTypes.array.isRequired
};

export default ActivityTable;