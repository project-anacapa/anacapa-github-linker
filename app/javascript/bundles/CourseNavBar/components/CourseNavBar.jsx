import React, {Component, Fragment} from 'react';
import * as PropTypes from 'prop-types';
import {Row, Col, MenuItem, Tab, Nav, NavItem, NavDropdown, Button} from "react-bootstrap";

class CourseNavBar extends Component {
    currentActiveTab = () => {
        // Captures path after the course index.
        // E.g. for path '/courses/1/project_teams/new', this captures 'project_teams'.
        const pathMatchRegex = new RegExp('\/courses\/[0-9]*/([^/]*)', 'i');
        const coursePathMatches = pathMatchRegex.exec(this.props.current_path);
        if (coursePathMatches == null || coursePathMatches.length <= 1) {
            return 'roster_students';
        }
        return coursePathMatches[1];
    }

    render() {
        const activeTabKey = this.currentActiveTab();
        return (
            <Fragment>
                <Nav bsStyle="tabs" activeKey={activeTabKey}>
                    <NavItem eventKey="roster_students" href={this.props.roster_path}>Students</NavItem>
                    <NavDropdown title="Teams">
                        <MenuItem eventKey="project_teams" href={this.props.project_teams_path}>Project Teams</MenuItem>
                        <MenuItem eventKey="org_teams" href={this.props.org_teams_path}>GitHub Teams</MenuItem>
                    </NavDropdown>
                    <NavItem eventKey="repos" href={this.props.repos_path}>Repositories</NavItem>
                    <NavItem eventKey="slack" href={this.props.slack_path}>Slack</NavItem>
                    <NavItem eventKey="jobs" href={this.props.jobs_path}>Jobs</NavItem>
                    <NavItem eventKey="edit" href={this.props.edit_path} disabled={!this.props.can_edit}>Edit Course</NavItem>
                </Nav>
            </Fragment>
        );
    }
}

CourseNavBar.propTypes = {
    current_path: PropTypes.string.isRequired,
    roster_path: PropTypes.string.isRequired,
    project_teams_path: PropTypes.string.isRequired,
    org_teams_path: PropTypes.string.isRequired,
    repos_path: PropTypes.string.isRequired,
    slack_path: PropTypes.string.isRequired,
    jobs_path: PropTypes.string.isRequired,
    edit_path: PropTypes.string.isRequired,
    can_edit: PropTypes.bool.isRequired
};

export default CourseNavBar;