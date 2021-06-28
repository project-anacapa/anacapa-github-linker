import React, { Component, Fragment } from 'react';
import {Panel, Grid} from "react-bootstrap";
import * as PropTypes from 'prop-types';
import CourseOrgTeamsTable from "./CourseOrgTeamsTable";
import CourseOrgTeamMemberList from "./CourseOrgTeamMemberList";

import OrgTeamsService from "../../../services/org-teams-service";
import CourseOrgTeamRepoList from './CourseOrgTeamRepoList';
import CommitsAnalytics from '../Analytics/CommitsAnalytics';


class CourseOrgTeam extends Component {

    constructor(props) {
        super(props);
        this.state = {team: undefined};
    }

    componentDidMount() {
        this.fetchTeam();
    }

    fetchTeam = () => {
        OrgTeamsService.getOrgTeam(this.props.course_id, this.props.org_team_id).then(
            (team) => {
                this.setState({team: team})
            }
        );
    }

    render() {
        const team = this.state.team;

        if (team == null) return "Loading...";

        return (
            <Fragment>
                <CourseOrgTeamsTable
                    teams={[team.org_team]}
                    page={1}
                    pageSize={1}
                    totalSize={1}
                    {...this.props}
                />
                <CourseOrgTeamMemberList 
                    team={team}
                    {...this.props}
                />
                <CourseOrgTeamRepoList
                    team={team}
                    {...this.props}
                />
                <Panel>
                    <Panel.Heading>
                            <Panel.Title>Analytics</Panel.Title>
                    </Panel.Heading>
                    <Panel.Body>
                        <div align="center">
                            <CommitsAnalytics
                                team={team}
                                {...this.props}
                            />
                        </div>
                    </Panel.Body>
                </Panel>
            </Fragment>
        );
    }
}

CourseOrgTeam.propTypes = {
    org_team_id: PropTypes.string.isRequired,
    course_id: PropTypes.string.isRequired
};

export default CourseOrgTeam;
