import React, { Component, Fragment } from 'react';
import BootstrapTable from 'react-bootstrap-table-next';

import PropTypes from 'prop-types';

class CourseOrgTeamRepoList extends Component {

    constructor(props) {
        super(props);
        this.state = {repoName: undefined};
    }

    columns =
        [
            {
                dataField: 'repo_name',
                text: 'Repository',
                editable: false,
                formatter: (cell, row, rowIndex, extraData) => this.renderRepoUrl(cell, row, rowIndex, { "course_id": this.props.team.course.course_organization })
            },
            {
                dataField: 'permission',
                text: 'Team Permission Level',
                editable: false,
                formatter: (cell, row, extraData) => this.renderRepoPermissionUrl(cell, row, { "course_id": this.props.team.course.course_organization, "team_id": this.props.team.org_team.name })
            },
        ];

    renderRepoUrl = (cell, row, rowIndex, extraData) => {
        const url = `https://github.com/${extraData.course_id}/${row.repo_name}`;

        return (
            <a href={url}>{cell}</a>
        );
    }

    renderRepoPermissionUrl = (cell, row, extraData) => {
        const url = `https://github.com/orgs/${extraData.course_id}/teams/${extraData.team_id}/repositories?query=${row.repo_name}`;

        return (
            <a href={url}>{cell}</a>
        );
    }

    render() {
        return (
            <Fragment>
                <BootstrapTable
                    bootstrap4={true}
                    columns={this.columns}
                    data={this.props.team.repos}
                    keyField="repo.id"                    
                />
            </Fragment>
        );
    }
}

CourseOrgTeamRepoList.propTypes = {
    team: PropTypes.object.isRequired,
};

export default CourseOrgTeamRepoList;
